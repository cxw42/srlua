local fl = require( "fltk4lua" )
local window = fl.Window( 340, 210, "Hello" )
fl.Box{ 20, 40, 300, 100, "Hello World!",
  box = "FL_UP_BOX", labelfont = "FL_HELVETICA_BOLD_ITALIC",
  labelsize = 36, labeltype = "FL_SHADOW_LABEL"
}
fl.Button{ 20, 150, 140, 30, "Print Me",
  user_data = "some Lua value", callback = print
}
local btn = fl.Button( 180, 150, 140, 30, "Quit" )
function btn:callback()
  window:hide()  -- will cleanly exit the application
end
window:end_group()
window:show( arg )
fl.run()
