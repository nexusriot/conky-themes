require 'cairo'

local function hex2rgb(h)
    h = h:gsub('#','')
    return tonumber('0x'..h:sub(1,2))/255,
           tonumber('0x'..h:sub(3,4))/255,
           tonumber('0x'..h:sub(5,6))/255
end

function conky_synthwave_draw()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(
        conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    local W = conky_window.width
    local H = conky_window.height

    local rp, gp, bp = hex2rgb('FF00FF')  -- magenta
    local rc, gc, bc = hex2rgb('00FFFF')  -- cyan
    local rh, gh, bh = hex2rgb('FF6EC7')  -- hot pink
    local ry, gy, by = hex2rgb('FFE000')  -- yellow-gold
    local rv, gv, bv = hex2rgb('9B30FF')  -- violet

    -- Retrowave sun: upper semicircle with horizontal stripe cuts
    local sun_cx = W / 2
    local sun_cy = 92   -- horizon line y-position
    local sun_r  = 76

    -- Outer glow halo
    cairo_set_source_rgba(cr, rp, gp, bp, 0.07)
    cairo_arc(cr, sun_cx, sun_cy, sun_r + 22, math.pi, 2*math.pi)
    cairo_fill(cr)
    cairo_set_source_rgba(cr, rh, gh, bh, 0.05)
    cairo_arc(cr, sun_cx, sun_cy, sun_r + 38, math.pi, 2*math.pi)
    cairo_fill(cr)

    -- Sun body: horizontal stripes clipped to upper semicircle
    -- Strip bands from top of sun down to horizon, gradient yellow→pink→magenta
    local stripe_count = 9
    local stripe_h = sun_r / stripe_count
    for i = 0, stripe_count - 1 do
        local t = i / (stripe_count - 1)
        -- colour interpolation: yellow (top) → hot pink → magenta (bottom)
        local sr, sg, sb
        if t < 0.5 then
            local u = t * 2
            sr = ry + (rh - ry) * u
            sg = gy + (gh - gy) * u
            sb = by + (bh - by) * u
        else
            local u = (t - 0.5) * 2
            sr = rh + (rp - rh) * u
            sg = gh + (gp - gh) * u
            sb = bh + (bp - bh) * u
        end
        -- y range of this stripe (stripes counted from top of sun going down)
        local y1 = sun_cy - sun_r + i * stripe_h
        local y2 = y1 + stripe_h - 1.5   -- 1.5px gap between stripes
        -- clip width to circle at midpoint of stripe
        local ym = (y1 + y2) / 2
        local dy = ym - sun_cy
        local hw = math.sqrt(math.max(0, sun_r*sun_r - dy*dy))
        cairo_set_source_rgba(cr, sr, sg, sb, 0.92)
        cairo_rectangle(cr, sun_cx - hw, y1, hw * 2, stripe_h - 1.5)
        cairo_fill(cr)
    end

    -- Sun outline (upper arc)
    cairo_set_line_width(cr, 2.0)
    cairo_set_source_rgba(cr, rh, gh, bh, 0.95)
    cairo_arc(cr, sun_cx, sun_cy, sun_r, math.pi, 2*math.pi)
    cairo_stroke(cr)

    -- Horizon line (full width, glowing magenta)
    cairo_set_line_width(cr, 1.5)
    cairo_set_source_rgba(cr, rp, gp, bp, 0.85)
    cairo_move_to(cr, 0, sun_cy)
    cairo_line_to(cr, W, sun_cy)
    cairo_stroke(cr)
    -- horizon glow (wider, dimmer)
    cairo_set_line_width(cr, 4.0)
    cairo_set_source_rgba(cr, rp, gp, bp, 0.18)
    cairo_move_to(cr, 0, sun_cy)
    cairo_line_to(cr, W, sun_cy)
    cairo_stroke(cr)

    -- Perspective grid below horizon
    local grid_bottom = sun_cy + 85
    local num_vert = 8
    local num_horiz = 5

    -- Vertical perspective lines converging to sun center at horizon
    cairo_set_line_width(cr, 1.0)
    for i = 0, num_vert do
        local bx = (i / num_vert) * W
        local dist = math.abs(bx - sun_cx) / (W / 2)
        cairo_set_source_rgba(cr, rp, gp, bp, 0.55 * (1 - dist * 0.35))
        cairo_move_to(cr, sun_cx, sun_cy)
        cairo_line_to(cr, bx, grid_bottom)
        cairo_stroke(cr)
    end

    -- Horizontal lines with perspective curvature
    for i = 1, num_horiz do
        local t = (i / num_horiz) ^ 1.6
        local hy = sun_cy + t * (grid_bottom - sun_cy)
        local hw = (t * W * 0.5)
        cairo_set_source_rgba(cr, rc, gc, bc, 0.40 * t)
        cairo_move_to(cr, sun_cx - hw, hy)
        cairo_line_to(cr, sun_cx + hw, hy)
        cairo_stroke(cr)
    end

    -- Corner brackets (alternating magenta/cyan)
    cairo_set_line_width(cr, 1.8)
    local arm = 20
    cairo_set_source_rgba(cr, rp, gp, bp, 0.85)
    cairo_move_to(cr, 0, arm);   cairo_line_to(cr, 0, 0);   cairo_line_to(cr, arm, 0);   cairo_stroke(cr)
    cairo_set_source_rgba(cr, rc, gc, bc, 0.85)
    cairo_move_to(cr, W-arm, 0); cairo_line_to(cr, W, 0);   cairo_line_to(cr, W, arm);   cairo_stroke(cr)
    cairo_set_source_rgba(cr, rc, gc, bc, 0.85)
    cairo_move_to(cr, 0, H-arm); cairo_line_to(cr, 0, H);   cairo_line_to(cr, arm, H);   cairo_stroke(cr)
    cairo_set_source_rgba(cr, rp, gp, bp, 0.85)
    cairo_move_to(cr, W-arm, H); cairo_line_to(cr, W, H);   cairo_line_to(cr, W, H-arm); cairo_stroke(cr)

    -- Section separators (alternating magenta/cyan gradient dots)
    local seps = {185, 300, 370, 450, 530}
    cairo_set_line_width(cr, 0.8)
    for i, sy in ipairs(seps) do
        local lr, lg, lb
        if i % 2 == 1 then lr, lg, lb = rp, gp, bp else lr, lg, lb = rc, gc, bc end
        cairo_set_source_rgba(cr, lr, lg, lb, 0.25)
        cairo_move_to(cr, 20, sy); cairo_line_to(cr, W-20, sy); cairo_stroke(cr)
        cairo_set_source_rgba(cr, lr, lg, lb, 0.75)
        cairo_rectangle(cr, 20, sy-2, 6, 4); cairo_fill(cr)
        cairo_rectangle(cr, W-26, sy-2, 6, 4); cairo_fill(cr)
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
