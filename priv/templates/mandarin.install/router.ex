
  pipeline :<%= install.context_underscore %>_layout do
    plug(:put_layout, {<%= install.web_module %>.<%= install.context_camel_case %>LayoutView, "layout.html"})
  end

  scope "/<%= install.context_underscore %>", <%= install.web_module %>.<%= install.context_camel_case %>, as: :<%= install.context_underscore %> do
    pipe_through([:browser, :<%= install.context_underscore %>_layout])
    # Add your routes here
    get "/", IndexController, :index
    # Routes will be added below the next line (don't delete it):
    # %% Mandarin Routes - <%= install.context_camel_case %> %%
  end
