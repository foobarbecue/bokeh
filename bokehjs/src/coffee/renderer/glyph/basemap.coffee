_ = require "underscore"
Glyph = require "./glyph"

class BasemapView extends Glyph.View

  _index_data: () ->
    @_xy_index()

  _set_data: () ->
    @image = (null for img in @url)
    @need_load = (true for img in @url)
    @loaded = (false for img in @url)
    @_xy_index()

  _map_data: () ->
    @sw = @sdist(@renderer.xmapper, @x, @w, 'edge', @mget('dilate'))
    @sh = @sdist(@renderer.ymapper, @y, @h, 'edge', @mget('dilate'))

  _render: (ctx, indices, {url, image, need_load, sx, sy, sw, sh, angle}) ->
    for i in indices
      if isNaN(sx[i]+sy[i]+angle[i])
        continue

      if need_load[i]
        img = new Image()
        img.onload = do (img, i) =>
          return () =>
            @loaded[i] = true
            image[i] = img
            @renderer.request_render()

        img.src = url[i]
        need_load[i] = false
      else if @loaded[i]
        @_render_image(ctx, i, image[i], sx, sy, sw, sh, angle)

  _final_sx_sy: (anchor, sx, sy, sw, sh) ->
    switch anchor
      when "top_left"      then [sx       , sy       ]
      when "top_center"    then [sx - sw/2, sy       ]
      when "top_right"     then [sx - sw  , sy       ]
      when "right_center"  then [sx - sw  , sy - sh/2]
      when "bottom_right"  then [sx - sw  , sy - sh  ]
      when "bottom_center" then [sx - sw/2, sy - sh  ]
      when "bottom_left"   then [sx       , sy - sh  ]
      when "left_center"   then [sx       , sy - sh/2]
      when "center"        then [sx - sw/2, sy - sh/2]

  _render_image: (ctx, i, image, sx, sy, sw, sh, angle) ->
    if isNaN(sw[i]) then sw[i] = image.width
    if isNaN(sh[i]) then sh[i] = image.height

    anchor = @mget('anchor') or "top_left"
    [sx, sy] = @_final_sx_sy(anchor, sx[i], sy[i], sw[i], sh[i])

    ctx.save()

    ctx.globalAlpha = @mget("global_alpha")

    if angle[i]
      ctx.translate(sx, sy)
      ctx.rotate(angle[i])
      ctx.drawImage(image, 0, 0, sw[i], sh[i])
      ctx.rotate(-angle[i])
      ctx.translate(-sx, -sy)
    else
      ctx.drawImage(image, sx, sy, sw[i], sh[i])
    ctx.restore()

class Basemap extends Glyph.Model
  default_view: BasemapView
  type: 'Basemap'
  visuals: []
  distances: ['w', 'h']
  angles: ['angle']
  fields: ['url:string']

  defaults: ->
    return _.extend {}, super(), {
      angle: 0
      global_alpha: 1.0
    }

  display_defaults: ->
    return _.extend {}, super(), {
    }

module.exports =
  Model: Basemap
  View: BasemapView
