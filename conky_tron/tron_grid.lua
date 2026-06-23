require 'cairo'

local function hex2rgb(h)
    h = h:gsub('#','')
    return tonumber('0x'..h:sub(1,2))/255,
           tonumber('0x'..h:sub(3,4))/255,
           tonumber('0x'..h:sub(5,6))/255
end

function conky_tron_draw()
    if conky_window == nil then return end
    local cs = cairo_xlib_surface_create(
        conky_window.display, conky_window.drawable,
        conky_window.visual, conky_window.width, conky_window.height)
    local cr = cairo_create(cs)

    local W = conky_window.width
    local H = conky_window.height
    local r,  g,  b  = hex2rgb('00BFFF')  -- electric blue
    local r2, g2, b2 = hex2rgb('00FFFF')  -- cyan accent
    local rd, gd, bd = hex2rgb('001A33')  -- dark grid

    -- Subtle background grid
    cairo_set_line_width(cr, 0.5)
    local gs = 24
    for xi = 0, W, gs do
        cairo_set_source_rgba(cr, rd, gd, bd, 0.55)
        cairo_move_to(cr, xi, 0)
        cairo_line_to(cr, xi, H)
        cairo_stroke(cr)
    end
    for yi = 0, H, gs do
        cairo_set_source_rgba(cr, rd, gd, bd, 0.55)
        cairo_move_to(cr, 0, yi)
        cairo_line_to(cr, W, yi)
        cairo_stroke(cr)
    end

    -- Corner L-brackets
    cairo_set_line_width(cr, 2.0)
    cairo_set_source_rgba(cr, r, g, b, 0.95)
    local arm = 22
    cairo_move_to(cr, 0, arm);   cairo_line_to(cr, 0, 0);   cairo_line_to(cr, arm, 0);   cairo_stroke(cr)
    cairo_move_to(cr, W-arm, 0); cairo_line_to(cr, W, 0);   cairo_line_to(cr, W, arm);   cairo_stroke(cr)
    cairo_move_to(cr, 0, H-arm); cairo_line_to(cr, 0, H);   cairo_line_to(cr, arm, H);   cairo_stroke(cr)
    cairo_move_to(cr, W-arm, H); cairo_line_to(cr, W, H);   cairo_line_to(cr, W, H-arm); cairo_stroke(cr)

    -- Inner bracket accent (offset 4px, dimmer)
    cairo_set_line_width(cr, 1.0)
    cairo_set_source_rgba(cr, r, g, b, 0.3)
    local ai = 4
    cairo_move_to(cr, ai, arm+ai);    cairo_line_to(cr, ai, ai);    cairo_line_to(cr, arm+ai, ai);    cairo_stroke(cr)
    cairo_move_to(cr, W-arm-ai, ai);  cairo_line_to(cr, W-ai, ai);  cairo_line_to(cr, W-ai, arm+ai);  cairo_stroke(cr)
    cairo_move_to(cr, ai, H-arm-ai);  cairo_line_to(cr, ai, H-ai);  cairo_line_to(cr, arm+ai, H-ai);  cairo_stroke(cr)
    cairo_move_to(cr, W-arm-ai, H-ai);cairo_line_to(cr, W-ai, H-ai);cairo_line_to(cr, W-ai, H-arm-ai);cairo_stroke(cr)

    -- Left-edge circuit traces (vertical segments with L-jogs)
    cairo_set_line_width(cr, 1.5)
    local tx = 7
    local traces = {
        {tx, 48,  tx,    92,   0.75},
        {tx, 92,  tx+10, 92,   0.75},
        {tx+10, 92,  tx+10, 118, 0.55},
        {tx, 165, tx,    210,  0.70},
        {tx, 210, tx+10, 210,  0.70},
        {tx+10, 210, tx+10, 238, 0.50},
        {tx, 278, tx,    320,  0.65},
        {tx, 320, tx+10, 320,  0.55},
        {tx, 385, tx,    428,  0.60},
        {tx, 470, tx,    512,  0.55},
        {tx, 512, tx+10, 512,  0.45},
    }
    for _, t in ipairs(traces) do
        cairo_set_source_rgba(cr, r2, g2, b2, t[5])
        cairo_move_to(cr, t[1], t[2])
        cairo_line_to(cr, t[3], t[4])
        cairo_stroke(cr)
        -- node dot at each endpoint
        cairo_set_source_rgba(cr, r, g, b, t[5] + 0.1)
        cairo_rectangle(cr, t[1]-2, t[2]-2, 4, 4)
        cairo_fill(cr)
        cairo_rectangle(cr, t[3]-2, t[4]-2, 4, 4)
        cairo_fill(cr)
    end

    -- Section separator lines with leading accent nodes
    cairo_set_line_width(cr, 1.0)
    local seps = {93, 212, 280, 358, 462, 540}
    for _, sy in ipairs(seps) do
        cairo_set_source_rgba(cr, r, g, b, 0.22)
        cairo_move_to(cr, 28, sy)
        cairo_line_to(cr, W - 8, sy)
        cairo_stroke(cr)
        cairo_set_source_rgba(cr, r2, g2, b2, 0.85)
        cairo_rectangle(cr, 28, sy-2, 5, 4)
        cairo_fill(cr)
        cairo_set_source_rgba(cr, r, g, b, 0.4)
        cairo_rectangle(cr, W-11, sy-1.5, 3, 3)
        cairo_fill(cr)
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end
