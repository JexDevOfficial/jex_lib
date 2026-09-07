JexConfig = {
    -- Only set this if you run a fork under a different resource name.
    Core = 'auto',

    -- How players interact with anything a Jex script puts in the world.
    --
    -- On 'auto' it uses whichever interaction resource you already run,
    -- and falls back to the game's own prompts if you run none. Every
    -- Jex script follows this, so your whole server behaves the same way.
    --
    --   auto          detect, else prompts
    --   prompt        native RDR2 prompts
    --   jex_interact  jex_interact
    --   ox_target     ox_target
    --   polly         polly_interact
    --   murphy        murphy_interact
    Interaction = 'auto',

    -- How close you have to be for something to be interactable.
    InteractDistance = 2.5,

    -- Notifications. Same idea as Interaction: if you already run
    -- something, Jex scripts use it rather than adding a second style.
    --
    --   auto               detect, else ours
    --   jex                the plain one built into jex_lib
    --   jex_notifications  jex_notifications
    --   ox_lib             ox_lib
    --   vorp               VORP's own
    --   redem              RedEM:RP's own
    Notify = 'auto',

    -- Only used by 'jex'. top-right, top-left, top-center,
    -- bottom-right or bottom-left.
    NotifyPosition = 'top-right',
    NotifyMax = 4,

    Debug = false,

    Accounts = {
        cash = 'cash',
        bank = 'bank',
        gold = 'gold',
    },
}
