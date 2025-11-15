-- Dark Neon Cyberpunk rings (1080p-tuned)
-- Requires conky with Lua/Cairo
require "cairo"

-- hex -> rgba(0..1)
local function rgba(hex, a)
  hex = (hex or ""):gsub("#","")
  if #hex ~= 6 then hex = "FFFFFF" end
  local r = tonumber(hex:sub(1,2),16)/255
  local g = tonumber(hex:sub(3,4),16)/255
  local b = tonumber(hex:sub(5,6),16)/255
  return r, g, b, a or 1.0
end

-- Neon palette
local CYAN    = "00F3FF"
local MAGENTA = "FF00DE"
local VIOLET  = "A066FF"
local GREEN   = "39FF14"
local AMBER   = "FFA500"

-- Coordinates are for a ~340px-wide top-right panel on 1080p
-- Adjust x/y if needed.
local RINGS = {
  -- Clock rings
  {x=120, y=150, r=54,  t=6,  start=0,   stop=360, color=CYAN,    key="${time %S}",          max=60},
  {x=120, y=150, r=70,  t=6,  start=0,   stop=360, color=MAGENTA, key="${time %M}",          max=60},
  {x=120, y=150, r=86,  t=8,  start=0,   stop=360, color=VIOLET,  key="${time %H}",          max=24},

  -- CPU / RAM cluster (shifted slightly down for 1080p)
  {x=300, y=125, r=42,  t=7,  start=-120, stop=120, color=GREEN,  key="${cpu}",               max=100},
  {x=300, y=125, r=56,  t=7,  start=-120, stop=120, color=AMBER,  key="${memperc}",           max=100},

  -- Root FS ring
  {x=300, y=230, r=48,  t=6,  start=-140, stop=140, color=CYAN,   key="${fs_used_perc /}",    max=100},
}

local function draw_ring(cr, pct, ring)
  local xc, yc, rad, th = ring.x, ring.y, ring.r, ring.t
  local sa = (ring.start - 90) * math.pi / 180
  local ea = (ring.stop  - 90) * math.pi / 180

  -- background arc
  local r,g,b,a = rgba(ring.color, 0.15)
  cairo_set_source_rgba(cr, r, g, b, a)
  cairo_set_line_width(cr, th)
  cairo_arc(cr, xc, yc, rad, sa, ea)
  cairo_stroke(cr)

  -- foreground arc
  local angle = sa + (ea - sa) * pct
  r,g,b,a = rgba(ring.color, 0.95)
  cairo_set_source_rgba(cr, r, g, b, a)
  cairo_set_line_width(cr, th)
  cairo_arc(cr, xc, yc, rad, sa, angle)
  cairo_stroke(cr)

  -- outer glow
  cairo_set_line_width(cr, th/2)
  cairo_set_source_rgba(cr, r, g, b, 0.25)
  cairo_arc(cr, xc, yc, rad + th*0.6, sa, angle)
  cairo_stroke(cr)
end

-- Conky calls this (lua_draw_hook_pre = 'draw_rings')
function conky_draw_rings()
  if conky_window == nil then return end

  local cs = cairo_xlib_surface_create(
    conky_window.display,
    conky_window.drawable,
    conky_window.visual,
    conky_window.width,
    conky_window.height
  )
  local cr = cairo_create(cs)

  local updates = tonumber(conky_parse("${updates}")) or 0
  if updates < 3 then
    cairo_destroy(cr); cairo_surface_destroy(cs)
    return
  end

  for _, ring in ipairs(RINGS) do
    local raw = conky_parse(ring.key)
    local val = tonumber(raw) or 0
    local pct = math.max(0, math.min(1, val / ring.max))
    draw_ring(cr, pct, ring)
  end

  cairo_destroy(cr)
  cairo_surface_destroy(cs)
end

-- Back-compat alias
function conky_draw_ring()
  conky_draw_rings()
end

