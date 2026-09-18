--require:2003600
--information:画像をパーツ分解し、特定番目だけを表示する（同一フレーム内でキャッシュ）

--[[pixelshader@mask_atlas:
---$include "./mask_atlas.hlsl"
]]

---$track:番目, min = 1, max = 1000, step = 1
local n = 1

---$track:透明度閾値, min = 0, max = 100, step = 0.1
local threshold = 25

threshold = threshold / 100

---$check:中心位置を変更
local move_center = true

--group:ソート,false

---$select:ソート方向
---X-→X+ / Y-→Y+=0
---X-→X+ / Y+→Y-=1
---X+→X- / Y-→Y+=2
---X+→X- / Y+→Y-=3
---Y-→Y+ / X-→X+=4
---Y-→Y+ / X+→X-=5
---Y+→Y- / X-→X+=6
---Y+→Y- / X+→X-=7
---Z（左上→右下 / x + w*y）=8
---Z（右下→左上 / -(x + w*y)）=9
---逆Z（右上→左下 / -x + w*y）=10
---逆Z（左下→右上 / x - w*y）=11
---N（右上→左下 / -x*h + y）=12
---N（左下→右上 / x*h - y）=13
---逆N（右下→左上 / -(x*h + y)）=14
---逆N（左上→右下 / x*h + y）=15
local sort_mode = 0

---$select:基準座標
---左上=0
---上=1
---右上=2
---左=3
---中心=4
---右=5
---左下=6
---下=7
---右下=8
local reference_point = 4

---$track:X量子化, min = 1, max = 256, step = 1
local quantize_x = 1

---$track:Y量子化, min = 1, max = 256, step = 1
local quantize_y = 1

---$track:X量子化シフト, min = -256, max = 256, step = 1
local quantize_shift_x = 0

---$track:Y量子化シフト, min = -256, max = 256, step = 1
local quantize_shift_y = 0

local FRAME_CACHE = { origin = nil, entries = {} }
pcall(function()
    local box = rawget(_G, "__pexisgle_np_cache")
    if type(box) == "table" then
        FRAME_CACHE = box
        return
    end
    rawset(_G, "__pexisgle_np_cache", FRAME_CACHE)
end)

local function round(num)
    return math.floor(num + 0.5)
end

local function hash_key(s)
    local h = 0
    for i = 1, #s do
        h = (h * 131 + s:byte(i)) % 2147483647
    end
    return tostring(h)
end

local function pixel_fingerprint()
    local w, h = obj.getpixel()
    if type(w) ~= "number" or type(h) ~= "number" then
        w, h = obj.w, obj.h
    end
    w = math.max(1, math.floor(w or 1))
    h = math.max(1, math.floor(h or 1))
    local pts = {
        { 0, 0 },
        { w - 1, 0 },
        { 0, h - 1 },
        { w - 1, h - 1 },
        { math.floor(w / 2), math.floor(h / 2) },
    }
    local parts = { tostring(w), tostring(h) }
    for i = 1, #pts do
        local x, y = pts[i][1], pts[i][2]
        if x < 0 then
            x = 0
        end
        if y < 0 then
            y = 0
        end
        local r, g, b, a = obj.getpixel(x, y, "rgb")
        parts[#parts + 1] = string.format("%s,%s,%s,%s", r, g, b, a)
    end
    return table.concat(parts, ";")
end

local function cache_id(quantize_x_int, quantize_y_int, quantize_shift_x_int, quantize_shift_y_int)
    local fields = {
        tostring(obj.getvalue("テキスト", "テキスト") or ""),
        tostring(obj.getvalue("テキスト", "フォント") or ""),
        tostring(obj.getvalue("テキスト", "サイズ") or ""),
        tostring(obj.w),
        tostring(obj.h),
        tostring(threshold),
        tostring(sort_mode),
        tostring(reference_point),
        tostring(quantize_x_int),
        tostring(quantize_y_int),
        tostring(quantize_shift_x_int),
        tostring(quantize_shift_y_int),
    }
    if type(obj.getvalue("テキスト", "テキスト")) ~= "string" then
        fields[#fields + 1] = pixel_fingerprint()
    end
    return hash_key(table.concat(fields, "\0"))
end

local function source_name(id)
    return "cache:pexisgle_np_" .. id .. "_s"
end

local function atlas_name(id)
    return "cache:pexisgle_np_" .. id .. "_a"
end

local function part_name(id, index)
    return "cache:pexisgle_np_" .. id .. "_p" .. tostring(index)
end

local function global_name(id)
    return "pexisgle_np_" .. id
end

local function serialize_parts(parts)
    local rows = {}
    for i = 1, #parts do
        local p = parts[i]
        rows[i] = string.format("%s,%s,%s,%s,%s,%s,%s", p.dx, p.dy, p.w, p.h, p.r, p.g, p.b)
    end
    return table.concat(rows, ";")
end

local function deserialize_parts(s)
    local parts = {}
    if type(s) ~= "string" or s == "" then
        return parts
    end
    for row in string.gmatch(s, "[^;]+") do
        local dx, dy, w, h, r, g, b = row:match("^([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+),([^,]+)$")
        parts[#parts + 1] = {
            dx = tonumber(dx),
            dy = tonumber(dy),
            w = tonumber(w),
            h = tonumber(h),
            r = tonumber(r),
            g = tonumber(g),
            b = tonumber(b),
        }
    end
    return parts
end

local function frame_entries()
    local origin = obj.originframe
    if FRAME_CACHE.origin ~= origin then
        FRAME_CACHE.origin = origin
        FRAME_CACHE.entries = {}
    end
    return FRAME_CACHE.entries
end

local function store_global(id, entry)
    global[global_name(id)] = string.format(
        "%s|%s|%s|%s",
        tostring(obj.originframe),
        tostring(entry.sw),
        tostring(entry.sh),
        serialize_parts(entry.parts)
    )
end

local function load_global(id)
    local raw = global[global_name(id)]
    if type(raw) ~= "string" then
        return nil
    end
    local frame, sw, sh, body = raw:match("^([^|]+)|([^|]+)|([^|]+)|(.*)$")
    if tonumber(frame) ~= obj.originframe then
        return nil
    end
    return {
        parts = deserialize_parts(body),
        sw = tonumber(sw),
        sh = tonumber(sh),
    }
end

local function load_disassembler()
    local ok, internal = pcall(function()
        return obj.module("disassembler")
    end)
    if not ok or type(internal) ~= "table" then
        error(
            "disassembler.mod2 が見つかりません。https://github.com/sevenc-nanashi/disassembler.anm2 をインストールしてください"
        )
    end
    return internal
end

local function destruct_entry(id, quantize_x_int, quantize_y_int, quantize_shift_x_int, quantize_shift_y_int)
    local internal = load_disassembler()
    obj.copybuffer("object", "cache:pexisgle_np_self")
    obj.copybuffer(source_name(id), "object")
    local data, source_width, source_height = obj.getpixeldata("object")
    obj.clearbuffer(atlas_name(id), source_width, source_height)
    local return_data, _, _ = obj.getpixeldata(atlas_name(id))
    local num_parts = internal.destruct(
        obj.effect_id,
        source_width,
        source_height,
        round(threshold * 255),
        sort_mode,
        reference_point,
        quantize_x_int,
        quantize_y_int,
        quantize_shift_x_int,
        quantize_shift_y_int,
        data,
        return_data
    )
    if num_parts == 0 then
        internal.dispose(obj.effect_id)
        return {
            parts = {},
            sw = source_width,
            sh = source_height,
        }
    end
    obj.putpixeldata(atlas_name(id), return_data, source_width, source_height)
    local parts = {}
    for i = 1, num_parts do
        local dx, dy, pwidth, pheight, key_red, key_green, key_blue = internal.get_part_image_info(obj.effect_id)
        parts[i] = {
            dx = dx,
            dy = dy,
            w = pwidth,
            h = pheight,
            r = key_red,
            g = key_green,
            b = key_blue,
        }
    end
    internal.dispose(obj.effect_id)
    return {
        parts = parts,
        sw = source_width,
        sh = source_height,
    }
end

local function ensure_entry(id, quantize_x_int, quantize_y_int, quantize_shift_x_int, quantize_shift_y_int)
    local entries = frame_entries()
    local entry = entries[id] or load_global(id)
    if entry then
        entries[id] = entry
        return entry
    end
    entry = destruct_entry(id, quantize_x_int, quantize_y_int, quantize_shift_x_int, quantize_shift_y_int)
    entries[id] = entry
    store_global(id, entry)
    return entry
end

local function extract_part(id, entry, part, index)
    local cached_part = part_name(id, index)
    if obj.copybuffer("object", cached_part) then
        return true
    end
    local ok = pcall(function()
        obj.clearbuffer(cached_part, part.w, part.h)
        obj.pixelshader("mask_atlas", cached_part, { source_name(id), atlas_name(id) }, {
            entry.sw,
            entry.sh,
            part.r / 255,
            part.g / 255,
            part.b / 255,
            part.dx,
            part.dy,
        }, "copy", "dot")
        if not obj.copybuffer("object", cached_part) then
            error("copy part")
        end
    end)
    return ok
end

local function apply_position(entry, part, oobj)
    local dx, dy = part.dx, part.dy
    local pwidth, pheight = part.w, part.h
    local source_width, source_height = entry.sw, entry.sh
    if move_center == true or move_center == 1 then
        obj.cx = 0
        obj.cy = 0
        obj.ox = dx + pwidth / 2 - oobj.cx - source_width / 2 + oobj.ox
        obj.oy = dy + pheight / 2 - oobj.cy - source_height / 2 + oobj.oy
    else
        obj.cx = -pwidth / 2 - dx + oobj.cx + source_width / 2
        obj.cy = -pheight / 2 - dy + oobj.cy + source_height / 2
        obj.ox = oobj.ox
        obj.oy = oobj.oy
    end
end

local function hide()
    obj.setoption("draw_state", true)
end

local oobj = {
    cx = obj.cx,
    cy = obj.cy,
    ox = obj.ox,
    oy = obj.oy,
}

obj.copybuffer("cache:pexisgle_np_self", "object")

local quantize_x_int = math.max(1, round(quantize_x))
local quantize_y_int = math.max(1, round(quantize_y))
local quantize_shift_x_int = round(quantize_shift_x)
local quantize_shift_y_int = round(quantize_shift_y)
local id = cache_id(quantize_x_int, quantize_y_int, quantize_shift_x_int, quantize_shift_y_int)
local entry = ensure_entry(id, quantize_x_int, quantize_y_int, quantize_shift_x_int, quantize_shift_y_int)
local part = entry.parts[n]
if not part then
    hide()
    return
end

if not extract_part(id, entry, part, n) then
    frame_entries()[id] = nil
    global[global_name(id)] = nil
    entry = destruct_entry(id, quantize_x_int, quantize_y_int, quantize_shift_x_int, quantize_shift_y_int)
    frame_entries()[id] = entry
    store_global(id, entry)
    part = entry.parts[n]
    if not part or not extract_part(id, entry, part, n) then
        hide()
        return
    end
end

apply_position(entry, part, oobj)
