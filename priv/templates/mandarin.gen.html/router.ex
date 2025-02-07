
  pipeline :<%= context.basename %>_layout do
    # Use our own layout for pages in this context
    plug(:put_root_layout, {<%= inspect context.web_module %>.<%= inspect context.alias %>.Layouts, :root})
  end

  scope "/<%= context.basename %>", <%= inspect context.web_module %>.<%= inspect context.alias %>, as: :<%= context.basename %> do
    pipe_through([:browser, :<%= context.basename %>_layout])
    # Add your routes here
    get "/", HomepageController, :homepage
    # Routes will be added below the next line (don't delete it):
    # %% Mandarin Routes - <%= inspect context.web_module %>.<%= inspect context.alias %> %%
  end
