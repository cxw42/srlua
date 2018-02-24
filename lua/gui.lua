-- gui.lua: GUI framework for Swiss
-- Copyright (c) 2018 Chris White.  CC-BY-SA 3.0.

-- atexit2, print_r, lfs, checks are already in the global space

local fl = require 'fltk4lua'
local original_print = _G.print
local window = nil
local browser = nil
local wizard = nil

-- Forward declarations
local btn_wizard_next = nil     -- "Next" button
local btn_wizard_prev = nil     -- "Previous" button
local screen_console = nil      -- Group holding the console browser
local screen_license = nil      -- Group holding the license screen
local rb_license_accept = nil   -- "Accept" radio button

--- Next/Previous button for the wizard.
--- @input b {mixed} Prev button, Next button, or false.
---                  If false, do not move next or prev.
local function wiz_next_prev_cb(b)
    local curr = wizard.value

    if curr == screen_console then  -- console: first page
        btn_wizard_next:activate()
        btn_wizard_prev:deactivate()
        if b == btn_wizard_next then
            wizard:next()
        end

    else    -- not the console
        btn_wizard_prev:activate()
        if rb_license_accept.value then
            btn_wizard_next:activate()
        else
            btn_wizard_next:deactivate()
        end
        if b == btn_wizard_next and rb_license_accept.value then
            wizard:next()
        elseif b == btn_wizard_prev then
            wizard:prev()
        end
    end

    -- Update tabs based on where we are now
    fl.check()
    if b then
        wiz_next_prev_cb(false)     -- false => no infinite recursion
    end

end --wiz_next_prev_cb()

local function start_gui()
    original_print('Starting GUI', InvokedAs)
    do  -- window elements
        window = assert(fl.Window( 640, 480, InvokedAs))

        do  -- create a wizard
            local wx, wy, ww, wh = 20, 20, 640-40, 480-100
            wizard = assert(fl.Wizard{wx, wy, ww, wh, box='FL_NO_BOX'})

            do  -- The console output as the first child of the wizard
                local g = assert(fl.Group(wx, wy, ww, wh))
                screen_console = g
                browser = assert(fl.Browser{20, 20, 640-40, 480-100,
                                        type='FL_SELECT_BROWSER'})
                g:end_group()
            end

            do  -- Second page: License agreement
                local g = assert(fl.Group{wx, wy, ww, wh, box='FL_NO_BOX'})
                screen_license = g

                local o = assert(
                    fl.Input{ wx, wy+25, ww, wh-100, "License agreement",})
                o.type = "FL_MULTILINE_OUTPUT"
                o.labelsize = 16
                o.align = fl.ALIGN_TOP + fl.ALIGN_LEFT
                o.value = "License agreement\nSome text here\n"
                o.value = o.value .. o.value .. o.value .. o.value .. o.value

                do  -- Accept/reject radios
                    local gx, gy = wx, wy+wh-80
                    local g = assert(fl.Group{
                      gx, gy, ww, 80,
                      --box="FL_THIN_UP_FRAME"
                    })

                    local function license_radio_cb(b)
                        if b == rb_license_accept then
                            btn_wizard_next:activate()
                        else
                            btn_wizard_next:deactivate()
                        end
                    end

                    local btn_reject = assert(fl.Round_Button{
                      gx, gy+10, ww, 30, "&Do not accept the license agreement",
                      --tooltip="Radio button",
                      type="FL_RADIO_BUTTON", down_box="FL_ROUND_DOWN_BOX",
                      value=true,
                      callback = license_radio_cb,
                    })

                    rb_license_accept = assert(fl.Round_Button{
                      gx, gy+40, ww, 30, "&Accept the license agreement",
                      --tooltip="Radio button",
                      type="FL_RADIO_BUTTON", down_box="FL_ROUND_DOWN_BOX",
                      callback = license_radio_cb,
                    })

                    g:end_group()
                end

                g:end_group()
            end

            wizard:end_group()
        end

        -- A divider
        local box = fl.Box{ 20, 420, 640-40, 2, "", box = "FL_UP_BOX" }
        if not box then error('Could not create box') end

        -- Buttons

        -- Cancel
        local button = assert(fl.Button{ 20, 435, 80, 30, "&Cancel",
            callback = function() window:hide() end
        })

        -- Prev
        btn_wizard_prev = assert(fl.Button{ 640-200, 435, 80, 30, "@< &Previous",
            callback = wiz_next_prev_cb
        })

        -- Next
        btn_wizard_next = assert(fl.Button{ 640-100, 435, 80, 30, "&Next @>",
            callback = wiz_next_prev_cb
        })
        btn_wizard_next:deactivate()     -- Until the license agreement is accepted

    end
    window:end_group()

    wizard.value = screen_license   -- start at the license screen

    window:show()
    --original_print 'GUI running'
    fl.check()
end

local function sprintf(...)
    --original_print('sprintf>', ...)
    local args=table.pack(...)
    local retval = ''
    if args.n == 0 then
        return ''
    end

    retval = tostring(args[1])
    for idx=2,args.n do
        retval = retval .. '\t' .. tostring(args[idx])
    end

    return retval
end --sprintf

local function output(...)
    if not window then start_gui() end

    local s = sprintf(...)
    --original_print('>',s)    --DEBUG
    -- Split at \n's because the browser doesn't handle them automatically
    for line in string.gmatch(s, '([^\n]*)') do
        browser:add(line)
    end
    browser.bottomline = browser.nitems
    fl.check()
end

return { start = start_gui, output = output, original_print = original_print }

-- vi: set ts=4 sts=4 sw=4 et ai fo-=ro ff=unix: --
