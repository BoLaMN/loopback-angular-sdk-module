'use strict'

angular.module 'loopback.sdk', [ 'ngResource' ]

.provider 'Resource', ($provide, $injector) ->
  baseRoute = ''
  baseConfig = {}

  id = parseInt(Math.random() * 0xFFFFFF, 10)
  index = parseInt(Math.random() * 0xFFFFFF, 10)
  pid = Math.floor(Math.random() * 100000) % 0xFFFF

  ObjectId = ->

    next = ->
      index = (index + 1) % 0xFFFFFF

    generate = ->
      time = parseInt((Date.now() / 1000), 10) % 0xFFFFFFFF

      hex(8, time) + hex(6, id) + hex(4, pid) + hex(6, next())

    hex = (length, n) ->
      n = n.toString(16)

      if n.length is length
        n
      else
        '00000000'.substring(n.length, length) + n

    buffer = (str) ->
      i = 0
      out = []

      while i < 24
        out.push(parseInt(str[i] + str[i + 1], 16))
        i += 2

      out

    buffer(generate()).map(hex.bind(this, 2)).join ''

  class ApiEndpoint
    constructor: (data = {}) ->
      for own key, value of data
        @[key] = value

      for own key, value of @defaults
        if angular.isUndefined @[key]
          @[key] = value()

      for own key, value of @properties
        if angular.isUndefined(@[key]) and Array.isArray value.type
          @[key] = []

  createClass = (name) ->
    name ?= ApiEndpoint.name
    args = ('a' + i for i in [1..ApiEndpoint.length]).join(', ')

    fnString = """
        return function (call) {
            return function #{name}(#{args}) {
                return call.apply(this, arguments)
            };
        };
    """

    newClass = (new Function(fnString)())(ApiEndpoint)

    F = ->

    F:: = Object.getPrototypeOf ApiEndpoint.prototype

    newClass:: = new F()
    newClass.prototype.constructor = newClass

    newClass

  define = (item, prop, desc) ->
    Object.defineProperty item, prop,
      writable: false
      enumerable: false
      value: desc

  createApiEndPoint = (modelName, baseConfig, baseRoute, config, $injector, $resource) ->
    resource = $resource baseRoute + config.url, config.params, config.methods

    resource::$save = (success, error) ->
      @$patchOrCreate()

    request = (action, args...) ->
      result = resource[action].call(this, args...)

      result.$promise or result

    newClass = createClass modelName
    baseModel = baseConfig.models[modelName] or {}

    properties = baseModel.properties or {}
    defaults = {}

    if angular.isObject properties
      angular.forEach properties, (property, propertyName) ->
        if Boolean(property.id) and property.type in [ '', 'ObjectID' ]
          defaults[propertyName] = ObjectId

        if property.default
          defaults[propertyName] = ->
            property.default

    define newClass.prototype, 'properties', properties
    define newClass.prototype, 'defaults', defaults

    if angular.isObject config.methods
      angular.forEach config.methods, (method, name) ->
        config.methods[name].url = baseRoute + method.url

      angular.forEach config.methods, (action, actionName) ->
        define newClass, actionName, angular.bind(this, request, actionName)

    if angular.isObject config.aliases
      angular.forEach config.aliases, (methodName, aliasName) ->
        define newClass, aliasName, angular.bind(this, request, config.methods[methodName])

    if angular.isObject config.scopes
      angular.forEach config.scopes, (scope, scopeName) ->
        define newClass, scopeName, createApiEndPoint scope.model, baseConfig, baseRoute, scope, $injector, $resource

    newClass

  setBaseRoute: (url) ->
    console.log 'setBaseRoute', url
    baseRoute = url

  setConfig: (newConfig) ->
    console.log 'config', newConfig
    baseConfig = newConfig

  registerModels: (url) ->
    if url
      baseRoute = url

    Object.keys(baseConfig.models).forEach (modelName) ->
      endpointConfig = baseConfig.models[modelName]

      $provide.factory modelName, [
        '$injector', '$resource', ($injector, $resource) ->
          createApiEndPoint modelName, baseConfig, baseRoute, endpointConfig, $injector, $resource
      ]

      return

  $get: angular.noop
