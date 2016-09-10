'use strict'

angular.module 'loopback.sdk', [ 'ngResource' ]

.provider 'Resource', ($provide, $injector) ->
  baseRoute = ''
  baseConfig = {}

  ###*
  # An api endpoint.
  #
  # @constructor
  # @param {string} baseRoute The server api's base route.
  # @param {ApiEndpointConfig} config Configuration object for the
  #     endpoint.
  # @param {!Object} $injector The angular $injector service.
  # @param {!Function} $resource The angular $resource service.
  ###

  class ApiEndpoint
    constructor: (data = {}) ->
      for own key, value of data
        @[key] = value

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
      action = if @id then '$replaceById' else '$create'
      @[action]()

    request = (action, params, data) ->
      resource[action](params, data).$promise

    newClass = createClass modelName

    define newClass, 'properties', baseConfig.models[modelName].properties

    methods = Object.keys config.methods

    methods.forEach (mthd) ->
      config.methods[mthd].url = baseRoute + config.methods[mthd].url

    angular.forEach config.methods, (action, actionName) ->
      define newClass, actionName, angular.bind(this, request, actionName)

    if angular.isObject config.aliases
      angular.forEach config.aliases, (methodName, aliasName) ->
        define newClass, aliasName, angular.bind(this, request, config.methods[methodName])

    angular.forEach config.scopes, (scope, scopeName) ->
      define newClass, scopeName, createApiEndPoint scope.model, baseConfig, baseRoute, scope, $injector, $resource

    newClass

  ###*
  # Function invoked by angular to get the instance of the api service.
  # @return {Object.<string, ApiEndpoint>} The set of all api endpoints.
  ###

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
