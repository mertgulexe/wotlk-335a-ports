-- Chain.lua: builds the chain graph of one quest and lays it out. Pure logic, no frames.
--
-- ns.Chain.Build(questID, opts) -> graph or nil (nil when the quest is not in ns.quests)
-- ns.Chain.Steps(questID, opts) -> step, steps, nodeCount (the same numbers Build gives)
--   opts.faction   "A" or "H" (nil: no faction filter)
--   opts.classBit  class bit, or nil for all classes
--   opts.raceBit   race bit, or nil for all races
--   opts.status    function(id) -> "completed", "active", "available", "locked",
--                  "unavailable", "otherclass" or "otherrace" (nil: every quest "available")
--
-- Coordinates are integers in a top-down system: x grows to the right, y grows downwards,
-- (0, 0) is the top left corner of the content. Rectangles are half-open: a card covers
-- [x, x + w) x [y, y + h).
local _, ns = ...

local Chain = {}
ns.Chain = Chain

local NODE_W, NODE_H = 200, 44
local HGAP = 16          -- between two slots of a layer
local DUMMY_W = 16       -- slot of a long edge's dummy point
local BASE_GAP = 26      -- gap between two layers with one channel
local CH_SPACING = 7     -- extra gap per extra channel
local CH_FIRST = 8       -- the first channel lies 8 px below the upper layer
local MARGIN = 12
local ENTRY_SPACING = 10 -- between two entries on a child's top edge
local LINE_W, OPT_W = 3, 2
local ARROW_W, ARROW_H = 9, 9
local DROP_INTO_ARROW = 5 -- a drop ends 5 px inside its arrow, so the line meets the arrow head
local MIN_SEP = 6         -- minimum distance between vertical lines of two sources in one gap
local ENTRY_INSET = 8     -- shifted entries stay this far inside a card's top edge
local MAX_SHIFT = 92      -- the largest shift of a card's entries (half a card minus the inset)

Chain.NODE_W, Chain.NODE_H, Chain.HGAP, Chain.DUMMY_W = NODE_W, NODE_H, HGAP, DUMMY_W
Chain.BASE_GAP, Chain.CH_SPACING, Chain.CH_FIRST, Chain.MARGIN = BASE_GAP, CH_SPACING, CH_FIRST, MARGIN
Chain.ENTRY_SPACING, Chain.LINE_W, Chain.OPT_W = ENTRY_SPACING, LINE_W, OPT_W
Chain.ARROW_W, Chain.ARROW_H = ARROW_W, ARROW_H
Chain.MIN_SEP, Chain.ENTRY_INSET, Chain.MAX_SHIFT = MIN_SEP, ENTRY_INSET, MAX_SHIFT

local band = bit.band
local floor = math.floor
local sort = table.sort
local ipairs, pairs = ipairs, pairs

-- the parent lists of a quest (who is a parent; the kind of each edge comes from ParentKindList)
local PARENT_KINDS = { { "pre", "req" }, { "one", "one" }, { "lead", "lead" }, { "bc", "opt" } }
Chain.PARENT_KINDS = PARENT_KINDS

-- ---------------------------------------------------------------- child index (static data)
local childIndex

local function Children()
    if childIndex then return childIndex end
    local idx = {}
    for id, q in pairs(ns.quests) do
        for _, pk in ipairs(PARENT_KINDS) do
            local list = q[pk[1]]
            if list then
                for i = 1, #list do
                    local p = list[i]
                    local c = idx[p]
                    if not c then c = {} idx[p] = c end
                    c[#c + 1] = id
                end
            end
        end
    end
    for p, c in pairs(idx) do
        sort(c)
        local out, last = {}, nil
        for i = 1, #c do
            if c[i] ~= last then out[#out + 1] = c[i] last = c[i] end
        end
        idx[p] = out
    end
    childIndex = idx
    return idx
end

-- children of a quest over all four edge kinds (sorted IDs; do not modify)
function Chain.ChildrenOf(id)
    return Children()[id]
end

-- forget the child index (the tests swap ns.quests)
function Chain.Reset()
    childIndex = nil
end

-- ---------------------------------------------------------------- visibility
local function MakeVisible(opts, root)
    local Q = ns.quests
    local fac, cb, rb = opts.faction, opts.classBit, opts.raceBit
    return function(id)
        local q = Q[id]
        if not q then return false end
        if id == root then return true end -- the selected quest is always visible
        if fac and q.fa and q.fa ~= fac then return false end
        if cb and q.cl and band(q.cl, cb) == 0 then return false end
        if rb and q.rc and band(q.rc, rb) == 0 then return false end
        return true
    end
end

-- the parents of a quest with the kind of edge each one gets, as Questie's IsDoable reads them:
-- - with a preQuestSingle list (one), the preQuestGroup list (pre) is not checked, so pre parents
--   that are not also in one only lead to the quest (kind lead, never blocking);
-- - without one, two pre parents that exclude each other (exclusiveTo, ex) are alternatives: either
--   one counts (kind one), unless the entry was negative in Questie (ps)
-- then lead and bc. A parent listed twice keeps its first kind.
local function ParentKindList(q)
    local out, seen = {}, {}
    local function add(p, kind)
        if not seen[p] then
            seen[p] = true
            out[#out + 1] = p
            out[#out + 1] = kind
        end
    end
    local Q = ns.quests
    if q.one then
        for _, p in ipairs(q.one) do add(p, "one") end
        for _, p in ipairs(q.pre or {}) do add(p, "lead") end
    elseif q.pre then
        local strict = {}
        for _, p in ipairs(q.ps or {}) do strict[p] = true end
        local inPre = {}
        for _, p in ipairs(q.pre) do inPre[p] = true end
        local alt = {}
        for _, p in ipairs(q.pre) do
            if not strict[p] then
                for _, x in ipairs(Q[p] and Q[p].ex or {}) do
                    if inPre[x] and not strict[x] then alt[p], alt[x] = true, true end
                end
            end
        end
        for _, p in ipairs(q.pre) do add(p, alt[p] and "one" or "req") end
    end
    for _, p in ipairs(q.lead or {}) do add(p, "lead") end
    for _, p in ipairs(q.bc or {}) do add(p, "opt") end
    return out
end
Chain.ParentKindList = ParentKindList
Chain.MakeVisible = MakeVisible

-- F(q) = ancestors(q) + q + descendants(q) + ancestors(descendants(q)) over visible quests
local function Family(root, vis)
    local Q = ns.quests
    local kids = Children()
    local set = { [root] = true }
    local function climb(start)
        local stack = { start }
        while #stack > 0 do
            local id = stack[#stack]
            stack[#stack] = nil
            local q = Q[id]
            for _, pk in ipairs(PARENT_KINDS) do
                local list = q[pk[1]]
                if list then
                    for i = 1, #list do
                        local p = list[i]
                        if not set[p] and vis(p) then
                            set[p] = true
                            stack[#stack + 1] = p
                        end
                    end
                end
            end
        end
    end
    climb(root)
    local desc, seen, stack = {}, { [root] = true }, { root }
    while #stack > 0 do
        local id = stack[#stack]
        stack[#stack] = nil
        local c = kids[id]
        if c then
            for i = 1, #c do
                local ch = c[i]
                if not seen[ch] and vis(ch) then
                    seen[ch] = true
                    desc[#desc + 1] = ch
                    stack[#stack + 1] = ch
                end
            end
        end
    end
    -- every descendant is a node before any of them is climbed, so climb() only has to
    -- expand parents that are new
    for i = 1, #desc do set[desc[i]] = true end
    for i = 1, #desc do climb(desc[i]) end
    return set
end

-- ---------------------------------------------------------------- nodes, edges, cycles, layers
local function Skeleton(root, opts)
    local Q = ns.quests
    if type(root) ~= "number" or not Q[root] then return nil end
    opts = opts or {}
    local vis = MakeVisible(opts, root)
    local set = Family(root, vis)
    local ids = {}
    for id in pairs(set) do ids[#ids + 1] = id end
    sort(ids)

    -- edges from each parent that is a node; one edge per (parent, child) pair
    local edges, outE, inE = {}, {}, {}
    for _, id in ipairs(ids) do outE[id], inE[id] = {}, {} end
    for _, id in ipairs(ids) do
        local pk = ParentKindList(Q[id])
        for i = 1, #pk, 2 do
            local p = pk[i]
            if set[p] then edges[#edges + 1] = { from = p, to = id, kind = pk[i + 1] } end
        end
    end
    -- outgoing edges in child-ID order (deterministic DFS)
    sort(edges, function(a, b)
        if a.from ~= b.from then return a.from < b.from end
        return a.to < b.to
    end)
    for _, e in ipairs(edges) do
        local o = outE[e.from]
        o[#o + 1] = e
    end

    -- cycles: DFS from the nodes in sorted ID order, back edges are dropped
    local state, dropped = {}, {}
    for _, start in ipairs(ids) do
        if not state[start] then
            state[start] = 1
            local stack = { { start, 0 } }
            while #stack > 0 do
                local top = stack[#stack]
                local o = outE[top[1]]
                top[2] = top[2] + 1
                local e = o[top[2]]
                if e then
                    local c = e.to
                    if state[c] == 1 then
                        e.dropped = true
                        dropped[#dropped + 1] = e
                    elseif not state[c] then
                        state[c] = 1
                        stack[#stack + 1] = { c, 0 }
                    end
                else
                    state[top[1]] = 2
                    stack[#stack] = nil
                end
            end
        end
    end
    local kept = {}
    for _, e in ipairs(edges) do
        if not e.dropped then kept[#kept + 1] = e end
    end
    for _, id in ipairs(ids) do outE[id] = {} end
    for _, e in ipairs(kept) do
        local o, i = outE[e.from], inE[e.to]
        o[#o + 1] = e
        i[#i + 1] = e
    end

    -- a child with a single remaining "one" parent requires it
    local oneCount = {}
    for _, e in ipairs(kept) do
        if e.kind == "one" then oneCount[e.to] = (oneCount[e.to] or 0) + 1 end
    end
    for _, e in ipairs(kept) do
        if e.kind == "one" and oneCount[e.to] == 1 then
            e.kind = "req"
            e.single = true
        end
    end

    -- longest-path layers (Kahn's order; the result does not depend on the order)
    local indeg, layer = {}, {}
    for _, id in ipairs(ids) do indeg[id], layer[id] = 0, 0 end
    for _, e in ipairs(kept) do indeg[e.to] = indeg[e.to] + 1 end
    local queue, head = {}, 1
    for _, id in ipairs(ids) do
        if indeg[id] == 0 then queue[#queue + 1] = id end
    end
    while head <= #queue do
        local id = queue[head]
        head = head + 1
        for _, e in ipairs(outE[id]) do
            local c = e.to
            if layer[id] + 1 > layer[c] then layer[c] = layer[id] + 1 end
            indeg[c] = indeg[c] - 1
            if indeg[c] == 0 then queue[#queue + 1] = c end
        end
    end
    if #queue ~= #ids then error("QuestsInChains: the chain graph still has a cycle") end
    local maxLayer = 0
    for _, id in ipairs(ids) do
        if layer[id] > maxLayer then maxLayer = layer[id] end
    end
    return {
        root = root, ids = ids, set = set, edges = kept, dropped = dropped,
        outE = outE, inE = inE, layer = layer, maxLayer = maxLayer,
        oneCount = oneCount,
    }
end

function Chain.Steps(root, opts)
    local sk = Skeleton(root, opts)
    if not sk then return nil end
    return sk.layer[root] + 1, sk.maxLayer + 1, #sk.ids
end

-- ---------------------------------------------------------------- ordering
-- barycenter sweeps: ties keep the current order, which comes from the initial
-- (level, ID) order, so the result is a strict total order and deterministic
local function KeyLess(a, b)
    if a.key ~= b.key then return a.key < b.key end
    return a.pos < b.pos
end
local function InitLess(a, b)
    if a.key ~= b.key then return a.key < b.key end
    if a.lv ~= b.lv then return a.lv < b.lv end
    if a.id ~= b.id then return a.id < b.id end
    return a.sub < b.sub
end

local function Renumber(list)
    for i = 1, #list do list[i].pos = i end
end

local function MeanPos(segs, side)
    local sum = 0
    for i = 1, #segs do sum = sum + segs[i][side].pos end
    return sum / #segs
end

-- ---------------------------------------------------------------- build
function Chain.Build(root, opts)
    opts = opts or {}
    local sk = Skeleton(root, opts)
    if not sk then return nil end
    local Q = ns.quests
    local status = opts.status or function() return "available" end
    local layer = sk.layer
    local maxLayer = sk.maxLayer

    -- real nodes
    local byId, nodes = {}, {}
    for _, id in ipairs(sk.ids) do
        local q = Q[id]
        local n = {
            id = id, sub = 0, lv = q.lv or 0, layer = layer[id], step = layer[id] + 1,
            ins = {}, outs = {}, status = status(id),
            parents = { req = {}, one = {}, lead = {}, opt = {} }, children = {},
        }
        byId[id] = n
        nodes[#nodes + 1] = n
    end

    -- segments; an edge over more than one layer gets a dummy point in each layer between
    local dummies, segments = {}, {}
    local function Segment(a, b, e)
        local s = { from = a, to = b, edge = e, kind = e.kind }
        a.outs[#a.outs + 1] = s
        b.ins[#b.ins + 1] = s
        segments[#segments + 1] = s
    end
    for _, e in ipairs(sk.edges) do
        local a, b = byId[e.from], byId[e.to]
        local pl = b.parents[e.kind]
        pl[#pl + 1] = e.from
        a.children[#a.children + 1] = e.to
        if e.kind == "opt" then a.leadIn = true end
        local prev = a
        for L = a.layer + 1, b.layer - 1 do
            local d = {
                dummy = true, layer = L, id = e.to, sub = e.from, lv = b.lv,
                origin = e.from, target = e.to, edge = e, ins = {}, outs = {},
            }
            dummies[#dummies + 1] = d
            Segment(prev, d, e)
            prev = d
        end
        Segment(prev, b, e)
    end
    for _, n in ipairs(nodes) do
        for _, list in pairs(n.parents) do sort(list) end
        sort(n.children)
        local oc = sk.oneCount[n.id]
        if oc and oc >= 2 then n.oneCount = oc end
        if #n.parents.lead >= 2 then n.leadCount = #n.parents.lead end
    end

    -- layers
    local layers = {}
    for L = 0, maxLayer do layers[L] = {} end
    for _, n in ipairs(nodes) do local l = layers[n.layer] l[#l + 1] = n end
    for _, d in ipairs(dummies) do local l = layers[d.layer] l[#l + 1] = d end

    -- initial order: layer 0 by (level, ID), later layers by (mean parent position, level, ID)
    for _, m in ipairs(layers[0]) do m.key = 0 end
    sort(layers[0], InitLess)
    Renumber(layers[0])
    for L = 1, maxLayer do
        for _, m in ipairs(layers[L]) do m.key = MeanPos(m.ins, "from") end
        sort(layers[L], InitLess)
        Renumber(layers[L])
    end
    -- four barycenter sweeps: down, up, down, up (ties broken by ID)
    local function Down()
        for L = 1, maxLayer do
            for _, m in ipairs(layers[L]) do m.key = MeanPos(m.ins, "from") end
            sort(layers[L], KeyLess)
            Renumber(layers[L])
        end
    end
    local function Up()
        for L = maxLayer - 1, 0, -1 do
            for _, m in ipairs(layers[L]) do
                if #m.outs > 0 then m.key = MeanPos(m.outs, "to") else m.key = m.pos end
            end
            sort(layers[L], KeyLess)
            Renumber(layers[L])
        end
    end
    Down() Up() Down() Up()

    -- x: each layer centred on the widest one
    local widths, widest = {}, 0
    for L = 0, maxLayer do
        local w = 0
        for i, m in ipairs(layers[L]) do
            m.w = m.dummy and DUMMY_W or NODE_W
            w = w + m.w + (i > 1 and HGAP or 0)
        end
        widths[L] = w
        if w > widest then widest = w end
    end
    for L = 0, maxLayer do
        local x = floor((widest - widths[L]) / 2)
        for _, m in ipairs(layers[L]) do
            m.x = x
            m.cx = x + floor(m.w / 2)
            x = x + m.w + HGAP
        end
    end

    -- y: one channel per source in each gap, left to right
    local tops, gaps, channels = {}, {}, {}
    local y = 0
    for L = 0, maxLayer do
        tops[L] = y
        for _, m in ipairs(layers[L]) do m.y, m.h = y, NODE_H end
        if L < maxLayer then
            local c = 0
            for _, m in ipairs(layers[L]) do
                if #m.outs > 0 then
                    c = c + 1
                    m.chY = y + NODE_H + CH_FIRST + (c - 1) * CH_SPACING
                end
            end
            channels[L] = c
            gaps[L] = BASE_GAP + (c - 1) * CH_SPACING
            y = y + NODE_H + gaps[L]
        end
    end

    -- entries: the k incoming segments of a child spread over its top edge, by source x
    for L = 0, maxLayer do
        for _, m in ipairs(layers[L]) do
            m.lx = m.cx -- x of the vertical line through a slot (stems, pass-throughs)
            local ins = m.ins
            sort(ins, function(a, b) return a.from.cx < b.from.cx end)
            local k = #ins
            for i, s in ipairs(ins) do
                s.ex = m.cx + (2 * i - k - 1) * ENTRY_SPACING / 2
                s.entry = i
            end
        end
    end
    -- A vertical line of one source must not run on (or right next to) the vertical line of
    -- another source in the same gap: a stem with a foreign drop below it reads as one edge.
    -- Gap by gap, top-down, each child shifts all of its entries by the smallest offset that
    -- keeps them MIN_SEP away from every foreign stem (a dummy moves its line inside its slot).
    for L = 0, maxLayer - 1 do
        local uppers = {}
        for _, s in ipairs(layers[L]) do
            if #s.outs > 0 then uppers[#uppers + 1] = s end
        end
        for _, t in ipairs(layers[L + 1]) do
            local ins = t.ins
            local function Conflicts(delta)
                local c = 0
                for _, seg in ipairs(ins) do
                    local x = seg.ex + delta
                    for _, s in ipairs(uppers) do
                        if s ~= seg.from then
                            local d = s.lx - x
                            if d < MIN_SEP and d > -MIN_SEP then c = c + 1 end
                        end
                    end
                end
                return c
            end
            local bestC = Conflicts(0)
            local best = 0
            if bestC > 0 then
                local lo, hi
                if t.dummy then
                    -- a 3 px line [lx - 1, lx + 2) stays inside the 16 px slot
                    lo, hi = (t.x + 1) - t.cx, (t.x + DUMMY_W - 2) - t.cx
                else
                    local first, last = ins[1].ex, ins[#ins].ex
                    lo = (t.x + ENTRY_INSET) - first
                    hi = (t.x + NODE_W - ENTRY_INSET) - last
                    if lo < -MAX_SHIFT then lo = -MAX_SHIFT end
                    if hi > MAX_SHIFT then hi = MAX_SHIFT end
                end
                local limit = (hi > -lo) and hi or -lo
                for d = 1, limit do
                    if d <= hi then
                        local c = Conflicts(d)
                        if c < bestC then best, bestC = d, c end
                    end
                    if bestC == 0 then break end
                    if -d >= lo then
                        local c = Conflicts(-d)
                        if c < bestC then best, bestC = -d, c end
                    end
                    if bestC == 0 then break end
                end
            end
            t.entryShift = best
            if best ~= 0 then
                for _, seg in ipairs(ins) do seg.ex = seg.ex + best end
                if t.dummy then t.lx = t.cx + best end
            end
        end
    end

    -- connectors
    local rects, arrows = {}, {}
    local function Origin(m) return m.dummy and m.origin or m.id end
    local completedCache = {}
    local function Completed(id)
        local v = completedCache[id]
        if v == nil then
            v = (byId[id] and byId[id].status or status(id)) == "completed"
            completedCache[id] = v
        end
        return v
    end
    for L = 0, maxLayer - 1 do
        for _, s in ipairs(layers[L]) do
            if #s.outs > 0 then
                local w = OPT_W
                for _, seg in ipairs(s.outs) do
                    if seg.kind ~= "opt" then w = LINE_W break end
                end
                s.lineW = w
                local origin = Origin(s)
                local fc = Completed(origin)
                local half = floor(w / 2)
                -- stem (a dummy's pass-through acts as its stem)
                local y0
                if s.dummy then
                    local src = s.ins[1].from
                    y0 = src.chY + src.lineW
                else
                    y0 = s.y + NODE_H
                end
                rects[#rects + 1] = {
                    x = s.lx - half, y = y0, w = w, h = s.chY - y0,
                    part = s.dummy and "pass" or "stem", kind = "stem", fromCompleted = fc,
                    from = origin, owner = s,
                }
                -- horizontal segment at the channel
                local minX, maxX = s.lx, s.lx
                for _, seg in ipairs(s.outs) do
                    if seg.ex < minX then minX = seg.ex end
                    if seg.ex > maxX then maxX = seg.ex end
                end
                rects[#rects + 1] = {
                    x = minX - half, y = s.chY, w = maxX - minX + w, h = w,
                    part = "h", kind = "stem", fromCompleted = fc, from = origin, owner = s,
                }
                -- drops and arrows into real children (a dummy child continues with its pass-through)
                for _, seg in ipairs(s.outs) do
                    local t = seg.to
                    if not t.dummy then
                        local wk = (seg.kind == "opt") and OPT_W or LINE_W
                        local top = s.chY + w
                        local bottom = t.y - ARROW_H + DROP_INTO_ARROW
                        rects[#rects + 1] = {
                            x = seg.ex - floor(wk / 2), y = top, w = wk, h = bottom - top,
                            part = "drop", kind = seg.kind, fromCompleted = fc,
                            from = origin, to = t.id, owner = s, target = t,
                        }
                        arrows[#arrows + 1] = {
                            x = seg.ex - floor(ARROW_W / 2), y = t.y - ARROW_H, w = ARROW_W, h = ARROW_H,
                            kind = seg.kind, fromCompleted = fc, from = origin, to = t.id, target = t,
                        }
                    end
                end
            end
        end
    end

    -- bounding box of everything drawn, then a margin of 12 on every side
    local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
    local function Grow(x, y, w, h)
        if x < minX then minX = x end
        if y < minY then minY = y end
        if x + w > maxX then maxX = x + w end
        if y + h > maxY then maxY = y + h end
    end
    for _, n in ipairs(nodes) do Grow(n.x, n.y, n.w, n.h) end
    for _, r in ipairs(rects) do Grow(r.x, r.y, r.w, r.h) end
    for _, a in ipairs(arrows) do Grow(a.x, a.y, a.w, a.h) end
    local dx, dy = MARGIN - minX, MARGIN - minY
    for _, list in ipairs({ nodes, dummies }) do
        for _, m in ipairs(list) do
            m.x, m.cx, m.lx, m.y = m.x + dx, m.cx + dx, m.lx + dx, m.y + dy
            if m.chY then m.chY = m.chY + dy end
        end
    end
    for _, list in ipairs({ rects, arrows }) do
        for _, r in ipairs(list) do r.x, r.y = r.x + dx, r.y + dy end
    end
    for _, seg in ipairs(segments) do seg.ex = seg.ex + dx end

    -- real nodes in reading order (layer, then left to right)
    local ordered = {}
    for L = 0, maxLayer do
        for _, m in ipairs(layers[L]) do
            if not m.dummy then
                m.order = #ordered + 1
                ordered[#ordered + 1] = m
            end
        end
    end
    local layerTops = {}
    for L = 0, maxLayer do layerTops[L] = tops[L] + dy end

    return {
        root = root, faction = opts.faction, classBit = opts.classBit,
        nodes = ordered, byId = byId, dummies = dummies, segments = segments,
        edges = sk.edges, dropped = sk.dropped, droppedCount = #sk.dropped,
        rects = rects, arrows = arrows, layers = layers, layerTops = layerTops,
        gaps = gaps, channels = channels,
        width = maxX - minX + 2 * MARGIN, height = maxY - minY + 2 * MARGIN,
        steps = maxLayer + 1, nodeCount = #ordered,
    }
end
