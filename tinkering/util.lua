
function tinkering.color_filter(texture, color)
	return texture.."^[multiply:"..color
end

function tinkering.combine_textures(tex1, tex2, color1, color2, offset, dp)
	local main_tex = tex1 .."\\^[multiply\\:".. color1
	local rod_tex  = tex2 .."\\^[multiply\\:".. color2

	return "[combine:16x16:"..offset.."="..main_tex..":0,0="..rod_tex
end
