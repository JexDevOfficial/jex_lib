Jex.Prompt = {}
local Prompt = Jex.Prompt

local groups = {}
local prompts = {}

local function varString(text)
    return CreateVarString(10, 'LITERAL_STRING', text)
end

-- Common RedM control hashes, so a script says 'e' rather than a number.
Prompt.Keys = {
    e = 0x760A9C6F,
    g = 0x760A9C6F,
    x = 0xC7B5340A,
    y = 0xF84FA74F,
    lb = 0xD9D0E1C0,
    rb = 0x156F7119,
    enter = 0xC7B5340A,
    space = 0xD9D0E1C0,
}

function Prompt.Group(label)
    local group = GetRandomIntInRange(0, 0xffffff)
    groups[group] = { label = label or '', prompts = {} }
    return group
end

function Prompt.Create(opts)
    local handle = PromptRegisterBegin()

    PromptSetControlAction(handle, opts.key or Prompt.Keys.e)
    PromptSetText(handle, varString(opts.label or ''))
    PromptSetEnabled(handle, opts.enabled ~= false)
    PromptSetVisible(handle, opts.visible ~= false)

    if opts.hold then
        PromptSetHoldMode(handle, true)
    else
        PromptSetStandardMode(handle, true)
    end

    if opts.group then
        PromptSetGroup(handle, opts.group)
        local g = groups[opts.group]
        if g then g.prompts[#g.prompts + 1] = handle end
    end

    PromptRegisterEnd(handle)

    prompts[#prompts + 1] = handle
    return handle
end

function Prompt.Pressed(handle)
    return PromptHasStandardModeCompleted(handle)
end

function Prompt.Completed(handle)
    return PromptHasHoldModeCompleted(handle)
end

function Prompt.SetEnabled(handle, on)
    PromptSetEnabled(handle, on)
end

function Prompt.SetVisible(handle, on)
    PromptSetVisible(handle, on)
end

function Prompt.SetLabel(handle, label)
    PromptSetText(handle, varString(label))
end

-- Call every frame the group should be on screen.
function Prompt.SetGroup(group)
    local g = groups[group]
    Citizen.InvokeNative(0xC65A45D4453C2627, group, varString(g and g.label or ''), 1)
end

function Prompt.Remove(handle)
    if not handle then return end

    PromptDelete(handle)

    for i, existing in ipairs(prompts) do
        if existing == handle then
            table.remove(prompts, i)
            break
        end
    end
end

function Prompt.RemoveAll()
    for _, handle in ipairs(prompts) do PromptDelete(handle) end
    prompts = {}
    groups = {}
end

--------------------------------------------------------------------------
-- Builder
--
-- Takes a list of options and gives back something with Show() and
-- Pressed(). Handles the group, the keys and the hold timers, so a
-- script never touches a prompt handle.
--------------------------------------------------------------------------

-- Assigned in order when an option does not name its own key.
local ORDER = { 0x760A9C6F, 0xC7B5340A, 0xF84FA74F, 0xD9D0E1C0, 0x156F7119, 0x6D1319BE }

function Prompt.Build(opts)
    local group = Prompt.Group(opts.label or '')
    local entries = {}

    for i, option in ipairs(opts.options or {}) do
        entries[#entries + 1] = {
            option = option,
            handle = Prompt.Create {
                label = option.label,
                key = option.key or ORDER[((i - 1) % #ORDER) + 1],
                group = group,
                hold = option.hold,
            },
        }
    end

    local builder = { group = group, entries = entries }

    -- Call every frame the prompts should be on screen. Options that
    -- cannot be used right now are greyed out rather than removed, so
    -- the list does not jump about as conditions change.
    function builder.Show()
        for _, entry in ipairs(entries) do
            local usable = not entry.option.canInteract or entry.option.canInteract()
            Prompt.SetEnabled(entry.handle, usable)
            Prompt.SetVisible(entry.handle, entry.option.hidden ~= true)
        end

        Prompt.SetGroup(group)
    end

    -- Returns the option that was just triggered, or nil.
    function builder.Pressed()
        for _, entry in ipairs(entries) do
            local done = entry.option.hold
                and Prompt.Completed(entry.handle)
                or Prompt.Pressed(entry.handle)

            if done then
                local usable = not entry.option.canInteract or entry.option.canInteract()
                if usable then return entry.option end
            end
        end
    end

    function builder.Remove()
        for _, entry in ipairs(entries) do Prompt.Remove(entry.handle) end
        entries = {}
    end

    return builder
end

AddEventHandler('onResourceStop', function(resource)
    if resource == Jex.resource then Prompt.RemoveAll() end
end)
