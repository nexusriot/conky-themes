require 'cairo'

-- Matrix columns state
local cols = {}
local num_cols = 0
local initialized = false
local last_w, last_h = 0, 0

local char_set = {
    "0","1","2","3","4","5","6","7","8","9",
    "A","B","C","D","E","F","G","H","I","J",
    "K","L","M","N","O","P","Q","R","S","T",
    "U","V","W","X","Y","Z",
    "ｱ","ｲ","ｳ","ｴ","ｵ",
    "ｶ","ｷ","ｸ","ｹ","ｺ",
    "ｻ","ｼ","ｽ","ｾ","ｿ"
}

local function rand_char()
    return char_set[math.random(#char_set)]
end

local function init_columns(w, h)
    cols = {}
    local char_width = 12 -- tuned with font size below
    num_cols = math.floor(w / char_width)

    for i = 1, num_cols do
        cols[i] = {
            x = (i - 1) * char_width,
            y = math.random(-h, 0),
            speed = math.random(6, 20) -- pixels per frame
        }
    end
end

function conky_matrix_draw()
    if conky_window == nil then
        return
    end

    local updates = tonumber(conky_parse('${updates}')) or 0
    if updates < 3 then
        return
    end

    local w = conky_window.width
    local h = conky_window.height

    local cs = cairo_xlib_surface_create(
        conky_window.display,
        conky_window.drawable,
        conky_window.visual,
        w,
        h
    )
    local cr = cairo_create(cs)

    cairo_select_font_face(
        cr, "DejaVu Sans Mono",
        CAIRO_FONT_SLANT_NORMAL,
        CAIRO_FONT_WEIGHT_NORMAL
    )
    cairo_set_font_size(cr, 14)

    if (not initialized) or w ~= last_w or h ~= last_h then
        math.randomseed(os.time())
        init_columns(w, h)
        initialized = true
        last_w, last_h = w, h
    end

    -- Slight dark fade to create trails
    cairo_set_source_rgba(cr, 0, 0, 0, 0.2)
    cairo_rectangle(cr, 0, 0, w, h)
    cairo_fill(cr)

    -- Draw matrix columns
    for i = 1, num_cols do
        local col = cols[i]

        -- Head (bright)
        cairo_set_source_rgba(cr, 0.8, 1.0, 0.8, 1.0)
        cairo_move_to(cr, col.x, col.y)
        cairo_show_text(cr, rand_char())

        -- Trail (dim)
        cairo_set_source_rgba(cr, 0.0, 1.0, 0.3, 0.9)
        cairo_move_to(cr, col.x, col.y - 16)
        cairo_show_text(cr, rand_char())

        -- Move down
        col.y = col.y + col.speed
        if col.y > h + 40 then
            col.y = math.random(-200, 0)
            col.speed = math.random(6, 20)
        end
    end

    cairo_destroy(cr)
    cairo_surface_destroy(cs)
end

