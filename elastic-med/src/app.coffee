results = require './modules/results'
state   = require './modules/state'
ejs     = require './modules/ejs'
query   = require './modules/query'
render  = require './modules/render'

helpers = require './modules/helpers'

# Router switching between pages.
Routing = can.Control

    init: ->
        # Load the components.
        for name in [ 'document', 'label', 'results', 'search', 'title' ]
            require "./components/#{name}"

        # Setup the UI.
        layout = require './templates/layout'
        @element.html render layout, helpers

    # Index.
    route: ->
        template = require './templates/page/index'
        @render(template, {}, 'ElasticMed')

    # Document detail.
    'doc/:oid route': ({ oid }) ->
        fin = (doc) =>
            template = require './templates/page/detail'
            title    = doc.attr('title').value
            @render template, doc, "#{title} - ElasticMed"

        # Find the document.
        doc = null
        # Is it in results?
        if (docs = results.attr('docs')).length
            docs.each (obj) ->
                # Found already?
                return if doc
                # Match on oid.
                doc = obj if obj.attr('oid') is oid

        # Found in results cache.
        return fin(doc) if doc
        
        # Get the document from the index.
        ejs.get oid, (err, doc) ->
            # Trouble? Not found etc.
            return state.error err if err
            fin(doc)
    
    # Render a page. Update the page title.
    render: (template, ctx, title) ->
        @element.find('.content')
        .html(render(template, ctx))
        # Update title.
        document.title = title

module.exports = (opts) ->
    { service, index, type } = opts
    # Init the client.
    ejs.attr { index, type, 'client': new $.es.Client 'hosts': service }

    # Start routing.
    new Routing opts.el
    do can.route.ready

    # Have we launched on the index?
    if can.route.current('')
        # Manually change the query to init the search.
        query opts.query or '' # '' is the default...