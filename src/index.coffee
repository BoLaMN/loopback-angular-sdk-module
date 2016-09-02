'use strict'

angular.module 'loopback.provider', [ 'ngResource' ]

.provider 'LoopBackResource', ($provide, $injector) ->
  baseRoute = ''
  config = {}

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
    constructor: (baseRoute, config, $injector, $resource) ->
      methods = Object.keys config.methods

      methods.forEach (mthd) ->
        config.methods[mthd].url = baseRoute + config.methods[mthd].url

      @resource = $resource baseRoute + config.url, config.params, config.methods

      @resource::$save = (success, error) ->
        action = if @id then '$replaceById' else '$create'
        @[action]()

      angular.forEach config.methods, (action, actionName) =>
        @[actionName] = angular.bind(this, @request, actionName)

      angular.forEach config.scopes, (scope, scopeName) =>
        @[scopeName] = new ApiEndpoint baseRoute, scope, $injector, $resource

    ###*
    # Perform a standard http request.
    #
    # @param {string} action The name of the action.
    # @param {Object=} params The parameters for the request.
    # @param {Object=} data The request data (for PUT / POST requests).
    # @return {angular.$q.Promise} A promise resolved when the http request has
    #     a response.
    ###

    request: (action, params, data) ->
      @resource[action](params, data).$promise

  ###*
  # Function invoked by angular to get the instance of the api service.
  # @return {Object.<string, ApiEndpoint>} The set of all api endpoints.
  ###

  setBaseRoute: (url) ->
    baseRoute = url

  setConfig: (newConfig) ->
    config = newConfig

  registerModels: (url) ->
    if url
      baseRoute = url

    Object.keys(config.models).forEach (modelName) ->
      endpointConfig = config.models[modelName]

      $provide.factory modelName, [
        '$injector', '$resource', ($injector, $resource) ->
          new ApiEndpoint baseRoute, endpointConfig, $injector, $resource
      ]

      return

  $get: angular.noop
