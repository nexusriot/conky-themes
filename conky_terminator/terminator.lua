require 'cairo'

local function hex2rgb(h)
    h = h:gsub('#','')
    return tonumber('0x'..h:sub(1,2))/255,
           tonumber('0x'..h:sub(3,4))/255,
           tonumber('0x'..h:sub(5,6))/255
end

function conky_terminator_draw()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(
        conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    local W = conky_window.width
    local H = conky_window.height
    local r,  g,  b  = hex2rgb('CC0000')  -- primary red
    local r2, g2, b2 = hex2rgb('FF2200')  -- hot red
    local ro, go, bo = hex2rgb('FF6600')  -- orange accent

    -- Horizontal CRT scanlines (every 6px, very subtle)
    cairo_set_line_width(cr, 1.0)
    for yi = 0, H, 6 do
        cairo_set_source_rgba(cr, r, g, b, 0.045)
        cairo_move_to(cr, 0, yi)
        cairo_line_to(cr, W, yi)
        cairo_stroke(cr)
    end

    -- Corner targeting brackets (double-line style)
    local arm = 28
    cairo_set_line_width(cr, 2.5)
    cairo_set_source_rgba(cr, r2, g2, b2, 0.92)
    cairo_move_to(cr, 0, arm);   cairo_line_to(cr, 0, 0);   cairo_line_to(cr, arm, 0);   cairo_stroke(cr)
    cairo_move_to(cr, W-arm, 0); cairo_line_to(cr, W, 0);   cairo_line_to(cr, W, arm);   cairo_stroke(cr)
    cairo_move_to(cr, 0, H-arm); cairo_line_to(cr, 0, H);   cairo_line_to(cr, arm, H);   cairo_stroke(cr)
    cairo_move_to(cr, W-arm, H); cairo_line_to(cr, W, H);   cairo_line_to(cr, W, H-arm); cairo_stroke(cr)
    -- inner dimmer double-bracket
    cairo_set_line_width(cr, 1.0)
    cairo_set_source_rgba(cr, r, g, b, 0.4)
    local ai = 5
    cairo_move_to(cr, ai, arm+ai);    cairo_line_to(cr, ai, ai);    cairo_line_to(cr, arm+ai, ai);    cairo_stroke(cr)
    cairo_move_to(cr, W-arm-ai, ai);  cairo_line_to(cr, W-ai, ai);  cairo_line_to(cr, W-ai, arm+ai);  cairo_stroke(cr)
    cairo_move_to(cr, ai, H-arm-ai);  cairo_line_to(cr, ai, H-ai);  cairo_line_to(cr, arm+ai, H-ai);  cairo_stroke(cr)
    cairo_move_to(cr, W-arm-ai, H-ai);cairo_line_to(cr, W-ai, H-ai);cairo_line_to(cr, W-ai, H-arm-ai);cairo_stroke(cr)

    -- Targeting reticle (centered near top, above stats)
    local cx = W / 2
    local cy = 52
    local rad = 24
    cairo_set_line_width(cr, 1.5)
    cairo_set_source_rgba(cr, r2, g2, b2, 0.75)
    cairo_arc(cr, cx, cy, rad, 0, 2*math.pi)
    cairo_stroke(cr)
    -- inner ring
    cairo_set_source_rgba(cr, ro, go, bo, 0.55)
    cairo_arc(cr, cx, cy, rad * 0.45, 0, 2*math.pi)
    cairo_stroke(cr)
    -- crosshair lines
    cairo_set_line_width(cr, 1.0)
    cairo_set_source_rgba(cr, r2, g2, b2, 0.55)
    cairo_move_to(cr, cx - rad - 10, cy); cairo_line_to(cr, cx - rad + 5, cy); cairo_stroke(cr)
    cairo_move_to(cr, cx + rad - 5, cy);  cairo_line_to(cr, cx + rad + 10, cy); cairo_stroke(cr)
    cairo_move_to(cr, cx, cy - rad - 10); cairo_line_to(cr, cx, cy - rad + 5); cairo_stroke(cr)
    cairo_move_to(cr, cx, cy + rad - 5);  cairo_line_to(cr, cx, cy + rad + 10); cairo_stroke(cr)
    -- tick marks on outer ring (at 45°)
    for _, a in ipairs({math.pi*0.25, math.pi*0.75, math.pi*1.25, math.pi*1.75}) do
        local tx1 = cx + math.cos(a) * (rad - 5)
        local ty1 = cy + math.sin(a) * (rad - 5)
        local tx2 = cx + math.cos(a) * (rad + 5)
        local ty2 = cy + math.sin(a) * (rad + 5)
        cairo_set_source_rgba(cr, ro, go, bo, 0.5)
        cairo_move_to(cr, tx1, ty1)
        cairo_line_to(cr, tx2, ty2)
        cairo_stroke(cr)
    end
    -- center dot
    cairo_set_source_rgba(cr, ro, go, bo, 0.95)
    cairo_arc(cr, cx, cy, 3, 0, 2*math.pi)
    cairo_fill(cr)

    -- THREAT LEVEL bar (CPU-driven, at bottom of window)
    local threat = tonumber(conky_parse('${cpu cpu0}')) or 0
    local bar_x = 22
    local bar_y = H - 14
    local bar_w = W - 44
    local fill_w = bar_w * (threat / 100)
    -- trough
    cairo_set_source_rgba(cr, r, g, b, 0.15)
    cairo_rectangle(cr, bar_x, bar_y, bar_w, 5)
    cairo_fill(cr)
    -- fill (orange low, red high)
    local fr, fg, fb
    if threat < 60 then fr, fg, fb = hex2rgb('FF6600')
    else fr, fg, fb = hex2rgb('FF0000') end
    cairo_set_source_rgba(cr, fr, fg, fb, 0.88)
    cairo_rectangle(cr, bar_x, bar_y, fill_w, 5)
    cairo_fill(cr)
    -- border
    cairo_set_source_rgba(cr, r2, g2, b2, 0.5)
    cairo_set_line_width(cr, 0.8)
    cairo_rectangle(cr, bar_x, bar_y, bar_w, 5)
    cairo_stroke(cr)

    -- Section separator ticks (horizontal line + left/right end ticks)
    local seps = {128, 248, 318, 398, 478}
    cairo_set_line_width(cr, 0.8)
    for _, sy in ipairs(seps) do
        cairo_set_source_rgba(cr, r, g, b, 0.28)
        cairo_move_to(cr, 22, sy); cairo_line_to(cr, W-22, sy); cairo_stroke(cr)
        cairo_set_source_rgba(cr, r2, g2, b2, 0.85)
        cairo_move_to(cr, 22, sy-4); cairo_line_to(cr, 22, sy+4); cairo_stroke(cr)
        cairo_move_to(cr, W-22, sy-4); cairo_line_to(cr, W-22, sy+4); cairo_stroke(cr)
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
