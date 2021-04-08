u = up.util
e = up.element

###**
Layers
======

TODO

@module up.layer
###
up.layer = do ->

  OVERLAY_CLASSES = [
    up.Layer.Modal
    up.Layer.Popup
    up.Layer.Drawer
    up.Layer.Cover
  ]
  OVERLAY_MODES = u.map(OVERLAY_CLASSES, 'mode')
  LAYER_CLASSES = [up.Layer.Root].concat(OVERLAY_CLASSES)

  ###**
  Configures default attributes for new overlays.

  All options for `up.layer.open()` may be configured. The configuration will also
  be used for `a[up-layer=new]` links.

  Defaults are configured separately for each [layer mode](/layer-terminology):

  | Object                    | Effect                       |
  |---------------------------|------------------------------|
  | `up.layer.config.root`    | Defaults for the root layer  |
  | `up.layer.config.modal`   | Defaults for modal overlays  |
  | `up.layer.config.drawer`  | Defaults for drawer overlays |
  | `up.layer.config.popup`   | Defaults for popup overlays  |
  | `up.layer.config.cover`   | Defaults for cover overlays  |

  For convenience you may configure options that affect all layer modes
  or all overlay modes:

  | Object                    | Effect                       |
  |---------------------------|------------------------------|
  | `up.layer.config.any`     | Defaults for all layers      |
  | `up.layer.config.overlay` | Defaults for all overlays    |

  Options configured in such a way are inherited.
  E.g. when you open a new drawer overlay, defaults from `up.layer.config.drawer`,
  `up.layer.config.overlay` and `up.layer.config.any` will be used (in decreasing priority).

  \#\#\# Example

  To make all modal overlays move in from beyond the top edge of the screen:

  ```js
  up.layer.config.modal.openAnimation = 'move-from-top'
  ```

  To configure an additional [main target](/main)
  for overlay of any mode:

  ```js
  up.layer.config.overlay.mainTargets.unshift('.content')
  ```

  \#\#\# Configuration inheritance

  @property up.layer.config

  @param {string} config.mode='modal'
    The default [mode](/layer-terminology) used when opening a new overlay.

  @param {object} config.any
    Defaults for all layer modes.

  @param {Array<string>} config.any.mainTargets
    An array of CSS selectors matching default render targets.

    This is an alias for `up.fragment.config.mainTargets`.

  @param {object} config.root
    Defaults for the [root layer](/layer-terminology).

    Inherits from `up.layer.config.any`.

  @param {object} config.root.mainTargets

  @param {object} config.overlay
    Defaults for all [overlays](/layer-terminology).

    In addition to the options documented here,
    all options for `up.layer.open()` may also be configured.

    Inherits from `up.layer.config.any`.

  @param {string|Function} config.overlay.openAnimation
    The opening animation.

  @param {number} config.overlay.openDuration
    The duration of the opening animation.

  @param {string} config.overlay.openEasing
    The easing function for the opening animation.

  @param {string|Function} config.overlay.closeAnimation
    The closing animation.

  @param {number} config.overlay.closeDuration
    The duration of the closing animation.

  @param {string} config.overlay.closeEasing
    The easing function for the opening animation.

  @param {string} config.overlay.dismissLabel
    The symbol for the dismiss icon in the top-right corner.

  @param {string} config.overlay.dismissAriaLabel
    The accessibility label for the dismiss icon in the top-right corner.

  @param {string|boolean} config.overlay.historyVisible='auto'
    Whether the layer's location or title will be visible in the browser's
    address bar and window title.

    If set to `'auto'`, the overlay will render history if its initial fragment
    is an [auto history target](/up.fragment.config.autoHistory).

    If set to `true`, the overlay will always render history.
    If set to `false`, the overlay will never render history.

  @param {object} config.modal
    Defaults for [modal overlays](/layer-terminology).

    Inherits from `up.layer.config.overlay` and `up.layer.config.any`.

  @param {object} config.cover
    Defaults for [cover overlays](/layer-terminology).

    Inherits from `up.layer.config.overlay` and `up.layer.config.any`.

  @param {object} config.drawer
    Defaults for [drawer overlays](/layer-terminology).

    Inherits from `up.layer.config.overlay` and `up.layer.config.any`.

  @param {object} config.popup
    Defaults for [popup overlays](/layer-terminology).

    Inherits from `up.layer.config.overlay` and `up.layer.config.any`.

  @stable
  ###
  config = new up.Config ->
    newConfig =
      mode: 'modal'
      any:
        mainTargets: [
          "[up-main='']",
          'main',
          ':layer' # this is <body> for the root layer
        ],
      root:
        mainTargets: ['[up-main~=root]']
        historyVisible: true
      overlay:
        mainTargets: ['[up-main~=overlay]']
        openAnimation: 'fade-in'
        closeAnimation: 'fade-out'
        dismissLabel: '×'
        dismissAriaLabel: 'Dismiss dialog'
        dismissable: true
        historyVisible: 'auto'
      cover:
        mainTargets: ['[up-main~=cover]']
      drawer:
        mainTargets: ['[up-main~=drawer]']
        backdrop: true
        position: 'left'
        size: 'medium'
        openAnimation: (layer) ->
          switch layer.position
            when 'left' then 'move-from-left'
            when 'right' then 'move-from-right'
        closeAnimation: (layer) ->
          switch layer.position
            when 'left' then 'move-to-left'
            when 'right' then 'move-to-right'
      modal:
        mainTargets: ['[up-main~=modal]']
        backdrop: true
        size: 'medium'
      popup:
        mainTargets: ['[up-main~=popup]']
        position: 'bottom'
        size: 'medium'
        align: 'left'
        dismissable: 'outside key'

    for Class in LAYER_CLASSES
      newConfig[Class.mode].Class = Class

    return newConfig

  stack = null

  handlers = []

  isOverlayMode = (mode) ->
    return u.contains(OVERLAY_MODES, mode)

  mainTargets = (mode) ->
    return u.flatMap(modeConfigs(mode), 'mainTargets')

  ###**
  Returns an array of config objects that apply to the given mode name.

  The config objects are in descending order of specificity.
  ###
  modeConfigs = (mode) ->
    if mode == 'root'
      return [config.root, config.any]
    else
      return [config[mode], config.overlay, config.any]
      
  normalizeOptions = (options) ->
    up.migrate.handleLayerOptions?(options)

    if u.isGiven(options.layer) # might be the number 0, which is falsy
      if options.layer == 'swap'
        options.layer = 'new'
        if up.layer.isOverlay()
          options.baseLayer = 'parent'
      else if options.layer == 'shatter'
        options.layer = 'new'
        options.baseLayer = 'root'

      if options.layer == 'new'
        # If the user wants to open a new layer, but does not pass a { mode },
        # we assume the default mode from up.layer.config.mode.
        options.mode ||= config.mode
      else if isOverlayMode(options.layer)
        # We allow passing an overlay mode in { layer }, which will
        # open a new layer with that mode.
        options.mode = options.layer
        options.layer = 'new'
    else
      # If no options.layer is given we still want to avoid updating "any" layer.
      # Other options might have a hint for a more appropriate layer.

      if options.mode
        # If user passes a { mode } option without a { layer } option
        # we assume they want to open a new layer.
        options.layer = 'new'
      else if u.isElementish(options.target)
        # If we are targeting an actual Element or jQuery collection (and not
        # a selector string) we operate in that element's layer.
        options.layer = stack.get(options.target, normalizeLayerOptions: false)
      else if options.origin
        # Links update their own layer by default.
        options.layer = 'origin'
      else
        # If nothing is given, we assume the current layer
        options.layer = 'current'

    options.context ||= {}

    # Remember the layer that was current when the request was made,
    # so changes with `{ layer: 'new' }` will know what to stack on.
    # Note if options.baseLayer is given, up.layer.get('current', options) will
    # return the resolved version of that.
    # TODO: Test this
    options.baseLayer = stack.get('current', u.merge(options, normalizeLayerOptions: false))

  build = (options) ->
    mode = options.mode
    Class = config[mode].Class

    # modeConfigs() returns the most specific options first,
    # but in merge() below later args override keys from earlier args.
    configs = u.reverse(modeConfigs(mode))
    options = u.mergeDefined(configs..., { mode, stack }, options)

    return new Class(options)

  openCallbackAttr = (link, attr) ->
    return e.callbackAttr(link, attr, ['layer'])

  closeCallbackAttr = (link, attr) ->
    return e.callbackAttr(link, attr, ['layer', 'value'])

  reset = ->
    config.reset()
    stack.reset()
    handlers = u.filter(handlers, 'isDefault')

  ###**
  [Opens a new overlay](/opening-overlays).

  Opening a layer is considered [navigation](/navigation) by default.

  \#\#\# Example

  ```js
  let layer = await up.layer.open({ url: '/contacts' })
  console.log(layer.mode) // logs "modal"
  ```

  @function up.layer.open

  @param {Object} [options]
    All [render options](/up.render) may be used.

    You may configure default layer attributes in `up.layer.config`.

  @param {string} [options.layer="new"]
    Whether to stack the new overlay or replace existing overlays.

    See [replacing existing overlays](/opening-layers#replacing-existing-overlays).

  @param {string} [options.mode]
    The kind of overlay to open.

    See [available layer modes](/layer-terminology#available-modes).

  @param {string} [options.size]
    The size of the overlay.

    Supported values are `'small'`, `'medium'`, `'large'` and `'grow'`:
    See [overlay sizes](/customizing-overlays#overlay-sizes) for details.

  @param {string} [options.class]
    An optional HTML class for the overlay's container element.

    See [overlay classes](/customizing-overlays#overlay-classes).

  @param {boolean|string|Array<string>} [options.dismissable=true]
    How the overlay may be [dismissed](/closing-overlays) by the user.

    Supported values are `'key'`, `'outside'` and `'button'`.
    See [user dismiss controls](/closing-overlays#user-facing-dismiss-controls)
    for details.

    You may enable multiple dismiss controls by passing an array or
    a space-separated string.

    Passing `true` or `false` will enable or disable all dismiss controls.

  @param {boolean|string} [options.historyVisible]
    Whether history of the overlay content is visible.

    If set to `true` the overlay location and title will be shown in browser UI.

    If set to `'auto'` history will be visible if the initial overlay
    content matches a [main target](/main).

  @param {string|Function} [options.animation]
    The opening animation.

  @param {Function(Event)} [options.onOpened]
    A function that is called when the overlay was inserted into the DOM.

    The function argument is an `up:layer:opened` event.

    The overlay may still play an opening animation when this function is called.
    To be called when the opening animation is done, pass an
    [`{ onFinished }`](/up.render#options.onFinished) option.

  @param {Function(Event)} [options.onAccepted]
    A function that is called when the overlay was [accepted](/closing-overlays).

    The function argument is an `up:layer:accepted` event.

  @param {Function(Event)} [options.onDismissed]
    A function that is called when the overlay was [dismissed](/closing-overlays).

    The function argument is an `up:layer:dismissed` event.

  @param {string|Array<string>} [options.acceptEvent]
    One or more event types that will cause this overlay to automatically be
    [accepted](/closing-overlays) when a matching event occurs within the overlay.

    The [overlay result value](/closing-overlays#overlay-result-values)
    is the event object that caused the overlay to close.

    See [Closing when an event is emitted](/closing-overlays#closing-when-an-event-is-emitted).

  @param {string|Array<string>} [options.dismissEvent]
    One or more event types that will cause this overlay to automatically be
    [dismissed](/closing-overlays) when a matching event occurs within the overlay.

    The [overlay result value](/closing-overlays#overlay-result-values)
    is the event object that caused the overlay to close.

    See [Closing when an event is emitted](/closing-overlays#closing-when-an-event-is-emitted).

  @param {string|Array<string>} [options.acceptLocation]
    One or more [URL patterns](/url-patterns) that will cause this overlay to automatically be
    [accepted](/closing-overlays) when the overlay reaches a matching [location](/up.layer.location).

    The [overlay result value](/closing-overlays#overlay-result-values)
    is an object of [named segments matches](/url-patterns#capturing-named-segments) captured
    by the URL pattern.

    See [Closing when a location is reached](/closing-overlays#closing-when-a-location-is-reached).

  @param {string|Array<string>} [options.dismissLocation]
    One or more [URL patterns](/url-patterns) that will cause this overlay to automatically be
    [dismissed](/closing-overlays) when the overlay reaches a matching [location](/up.layer.location).

    The [overlay result value](/closing-overlays#overlay-result-values)
    is an object of [named segments matches](/url-patterns#capturing-named-segments) captured
    by the URL pattern.

    See [Closing when a location is reached](/closing-overlays#closing-when-a-location-is-reached).

  @param {Object} [options.context={}]
    The initial [context](/up.layer.context) object for the new overlay.

  @param {string} [options.position]
    The position of the popup relative to the `{ origin }` element that opened
    the overlay.

    Supported values are `'top'`,  `'right'`,  `'bottom'` and  `'left'`.

    See [popup position](/customizing-overlays#popup-position).

  @param {string} [options.align]
    The alignment of the popup within its `{ position }`.

    Supported values are `'top'`,  `'right'`, `'center'`, `'bottom'` and  `'left'`.

    See [popup position](/customizing-overlays#popup-position).

  @return {Promise<up.Layer>}
    A promise for the `up.Layer` object that models the new overlay.

    The promise will be resolved once the overlay was placed into the DOM.

  @stable
  ###
  open = (options) ->
    options = u.options(options,
      layer: 'new',
      defaultToEmptyContent: true,
      navigate: true
    )

    # Even if we are given { content } we need to pipe this through up.render()
    # since a lot of options processing is happening there.
    return up.render(options).then (result) -> return result.layer

  ###**
  @event up:layer:opened
  @stable
  ###

  ###**
  This event is emitted after a layer's [location property](/up.Layer#location)
  has changed value.

  This event is also emitted when a layer [without history](/up.Layer#history)
  has reached a new location.

  @param {string} event.location
    The new location URL.
  @event up:layer:location:changed
  @experimental
  ###

  ###**
  Opens an overlay and returns a promise for its [acceptance](/closing-overlays).

  It's useful to think of overlays as [promises](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Promise)
  which may either be **fulfilled (accepted)** or **rejected (dismissed)**.

  \#\#\# Example

  Instead of using `up.layer.open()` and passing callbacks, you may use `up.layer.ask()`.
  `up.layer.ask()` returns a promise for the acceptance value, which you can `await`:

  ```js
  let user = await up.layer.ask({ url: '/users/new' })
  console.log("New user is " + user)
  ```

  @see closing-overlays

  @function up.layer.ask

  @param {Object} options
    See options for `up.layer.open()`.

  @return {Promise}
    A promise that will settle when the overlay closes.

    When the overlay was accepted, the promise will fulfill with the overlay's acceptance value.
    When the overlay was dismissed, the promise will reject with the overlay's dismissal value.

  @stable
  ###
  ask = (options) ->
    return new Promise (resolve, reject) ->
      options = u.merge options,
        onAccepted: (event) -> resolve(event.value)
        onDismissed: (event) -> reject(event.value)
      open(options)

  anySelector = ->
    u.map(LAYER_CLASSES, (Class) -> Class.selector()).join(',')

  optionToString = (option) ->
    if u.isString(option)
      return "layer \"#{option}\""
    else
      return option.toString()

  ###**
  [Follows](/a-up-follow) this link and opens the result in a new layer.

  \#\#\# Example

  ```html
  <a href="/menu" up-layer="new">Open menu</a>
  ```

  @selector a[up-layer=new]

  @params-note
    All attributes for `a[up-follow]` may also be used.

    You may configure default layer attributes in `up.layer.config`.

  @param {string} [up-layer="new"]
    Whether to stack the new overlay onto the current layer or replace existing overlays.

    See [replacing existing overlays](/opening-layers#replacing-existing-overlays).

  @param [up-mode]
    The kind of overlay to open.

    See [available layer modes](/layer-terminology#available-modes).

  @param [up-size]
    The size of the overlay.

    See [overlay sizes](/customizing-overlays#overlay-sizes) for details.

  @param [up-class]
    An optional HTML class for the overlay's container element.

    See [overlay classes](/customizing-overlays#overlay-classes).

  @param [up-history-visible]
    Whether history of the overlay content is visible.

    If set to `true` the overlay location and title will be shown in browser UI.

    If set to `'auto'` history will be visible if the initial overlay
    content matches a [main target](/main).

  @param [up-dismissable]
    How the overlay may be [dismissed](/closing-overlays) by the user.

    See [user dismiss controls](/closing-overlays#user-facing-dismiss-controls)
    for details.

    You may enable multiple dismiss controls by passing a space-separated string.

    Passing `true` or `false` will enable or disable all dismiss controls.

  @param [up-animation]
    The name of the opening animation.

  @param [up-on-opened]
    A JavaScript snippet that is called when the overlay was inserted into the DOM.

    The snippet runs in the following scope:

    | Expression | Value                                    |
    |------------|------------------------------------------|
    | `this`     | The link that opened the overlay         |
    | `layer`    | An `up.Layer` object for the new overlay |
    | `event`    | An `up:layer:opened` event               |

  @param [up-on-accepted]
    A JavaScript snippet that is called when the overlay was [accepted](/closing-overlays).

    The snippet runs in the following scope:

    | Expression | Value                                         |
    |------------|-----------------------------------------------|
    | `this`     | The link that originally opened the overlay   |
    | `layer`    | An `up.Layer` object for the accepted overlay |
    | `value`    | The overlay's [acceptance value](/closing-overlays#overlay-result-values) |
    | `event`    | An `up:layer:accepted` event                  |

  @param [up-on-dismissed]
    A JavaScript snippet that is called when the overlay was [dismissed](/closing-overlays).

    The snippet runs in the following scope:

    | Expression | Value                                          |
    |------------|------------------------------------------------|
    | `this`     | The link that originally opened the overlay    |
    | `layer`    | An `up.Layer` object for the dismissed overlay |
    | `value`    | The overlay's [dismissal value](/closing-overlays#overlay-result-values) |
    | `event`    | An `up:layer:dismissed` event                   |

  @param [up-accept-event]
    One or more event types that will cause this overlay to automatically be
    [accepted](/closing-overlays) when a matching event occurs within the overlay.

    The [overlay result value](/closing-overlays#overlay-result-values)
    is the event object that caused the overlay to close.

    See [Closing when an event is emitted](/closing-overlays#closing-when-an-event-is-emitted).

  @param [up-dismiss-event]
    One or more event types that will cause this overlay to automatically be
    [dismissed](/closing-overlays) when a matching event occurs within the overlay.

    The [overlay result value](/closing-overlays#overlay-result-values)
    is the event object that caused the overlay to close.

    See [Closing when an event is emitted](/closing-overlays#closing-when-an-event-is-emitted).

  @param [up-accept-location]
    One or more [URL patterns](/url-patterns) that will cause this overlay to automatically be
    [accepted](/closing-overlays) when the overlay reaches a matching [location](/up.layer.location).

    The [overlay result value](/closing-overlays#overlay-result-values)
    is an object of [named segments matches](/url-patterns#capturing-named-segments) captured
    by the URL pattern.

    See [Closing when a location is reached](/closing-overlays#closing-when-a-location-is-reached).

  @param [up-dismiss-location]
    One or more [URL patterns](/url-patterns) that will cause this overlay to automatically be
    [dismissed](/closing-overlays) when the overlay reaches a matching [location](/up.layer.location).

    The [overlay result value](/closing-overlays#overlay-result-values)
    is an object of [named segments matches](/url-patterns#capturing-named-segments) captured
    by the URL pattern.

    See [Closing when a location is reached](/closing-overlays#closing-when-a-location-is-reached).

  @param [up-context]
    The new overlay's [context](/up.layer.context) object, encoded as JSON.

  @param [up-position]
    The position of the popup relative to the `{ origin }` element that opened
    the overlay.

    Supported values are `top`,  `right`,  `bottom` and  `left`.

    See [popup position](/customizing-overlays#popup-position).

  @param [up-align]
    The alignment of the popup within its `{ position }`.

    Supported values are `top`,  `right`, `center`, `bottom` and  `left`.

    See [popup position](/customizing-overlays#popup-position).

  @stable
  ###

  ###**
  [Dismisses](/closing-overlays) the [current layer](/up.layer.current) when the link is clicked.

  The JSON value of the `[up-accept]` attribute becomes the overlay's
  [dismissal value](/closing-overlays#overlay-result-values).

  \#\#\# Example

  ```html
  <a href='/dashboard' up-dismiss>Close</a>
  ```

  \#\#\# Fallback for the root layer

  The link's `[href]` will only be followed when this link is clicked in the [root layer](/up.layer).
  In an overlay the `click` event's default action is prevented.

  You can also omit the `[href]` attribute to make a link that only works in overlays.

  @selector a[up-dismiss]
  @param [up-dismiss]
    The overlay's [dismissal value](/closing-overlays#overlay-result-values) as a JSON string.
  @param [up-confirm]
    A message the user needs to confirm before the layer is closed.
  @param [up-animation]
    The overlay's close animation.

    Defaults to overlay's [preconfigured close animation](/up.layer.config).
  @param [up-duration]
    The close animation's duration in milliseconds.
  @param [up-easing]
    The close animation's easing function.
  @stable
  ###

  ###**
  [Accepts](/closing-overlays) the [current layer](/up.layer.current) when the link is clicked.

  The JSON value of the `[up-accept]` attribute becomes the overlay's
  [acceptance value](/closing-overlays#overlay-result-values).

  \#\#\# Example

  ```html
  <a href='/users/5' up-accept='{ "id": 5 }'>Choose user #5</a>
  ```

  \#\#\# Fallback for the root layer

  The link's `[href]` will only be followed when this link is clicked in the [root layer](/up.layer).
  In an overlay the `click` event's default action is prevented.

  You can also omit the `[href]` attribute to make a link that only works in overlays.

  @selector a[up-accept]
  @param [up-accept]
    The overlay's [acceptance value](/closing-overlays#overlay-result-values) as a JSON string.
  @param [up-confirm]
    A message the user needs to confirm before the layer is closed.
  @param [up-duration]
    The close animation's duration in milliseconds.
  @param [up-easing]
    The close animation's easing function.
  @stable
  ###

  up.on 'up:fragment:destroyed', (event) ->
    stack.sync()

  up.on 'up:framework:boot', ->
    stack = new up.LayerStack()

  up.on 'up:framework:reset', reset

  api = u.literal({
    config
    mainTargets
    open
    build
    ask
    normalizeOptions
    openCallbackAttr
    closeCallbackAttr
    anySelector
    optionToString
    get_stack: -> stack
  })

  ###**
  Returns the current layer in the [layer stack](/up.layer.stack).

  The *current* layer is usually the [frontmost layer](/up.layer.front).
  There are however some cases where the current layer is a layer in the background:

  - While an element in a background layer is [compiled](/up.compiler).
  - While an Unpoly event like `up:request:loaded` is being triggered from a background layer.
  - While a running event listener was bound to a background layer using `up.Layer#on()`.

  To temporarily change the current layer from your own code, use `up.Layer#asCurrent()`.

  @property up.layer.current
  @param {up.Layer} layer
  @stable
  ###

  ###**
  Returns the number of layers in the [layer stack](/up.layer.stack).

  The count includes the [root layer](/up.layer.root).
  Hence a page with a single overlay would return a count of 2.

  @property up.layer.count
  @param {number} count
    The number of layers in the stack.
  @stable
  ###
  u.delegate(api, [
    'get'
    'getAll'
    'root'
    'overlays'
    'current'
    'front'
    'sync'
    'count'
    'dismissAll'
  ], -> stack)

  u.delegate(api, [
    'accept'
    'dismiss'
    'isRoot'
    'isOverlay'
    'on'
    'off'
    'emit'
    'parent'
    'child'
    'ancestor'
    'descendants'
    'historyVisible'
    'location'
    'title'
    'mode'
    'context'
    'element'
    'contains'
    'size'
    'origin'
    'affix'
    'dismissable'
  ], -> stack.current)

  return api

u.getter up, 'context', -> up.layer.context
