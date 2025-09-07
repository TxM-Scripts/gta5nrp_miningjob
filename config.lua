Config = {}

Config.Jobs = {
    Mining = {
        JobName = "mining",
        JobLabel = "Đào đá",
        Ped = "mp_m_forgery_01",

        PedBlip = {
            Enable = true,
            Sprite = 1,
            Color = 1,
            Scale = 0.6,
            Title = "~g~[Nghề Sạch]~s~ Đào Đá",
            Coords = vec4(2943.31, 2745.95, 43.31, 280.47),
        },

        Digging = {
            Marker = { type = 1, size = vec3(5.5,5.5,10.5), color = {0,255,0,180} },
            Blip   = { Sprite = 2, Color = 1, Scale = 0.8, Label = "Mỏ đá" },
            Locations = {
                vec4(2993.1, 2784.86, 43.65, 220.31),
            }
        },

        Crushing = {
            Marker = { type = 1, size = vec3(3.0,3.0,6.0), color = {0,100,255,180} },
            Blip   = { Sprite = 2, Color = 1, Scale = 0.8, Label = "Kho đá" },
            Locations = {
                vec4(2945.07, 2799.75, 41.02, 108.37),
            }
        },

        Smelting = {
            Marker = { type = 1, size = vec3(3.0,3.0,6.0), color = {255,165,0,180} },
            Blip   = { Enable = true, Sprite = 436, Color = 5, Scale = 0.8, Label = "Lò Luyện Quặng" },
            Locations = {
                vec4(2945.07, 2799.75, 41.02, 108.37),
            },
            Prop = "v_ilev_found_cranebucket",
        },

        Props = {
            Tool = "prop_tool_pickaxe",
            Rock = "rock_4_cl_2_2"
        },

        Animations = {
            Mining = { dict = "melee@large_wpn@streamed_core", clip = "ground_attack_on_spot" },
            Carry  = { dict = "anim@heists@box_carry@", clip = "idle" }
        },
        Tool = {
            Name = "pickaxe"
        },
        Reward = {
            Crushing = {
                { name = "raw_stone", amount = 1 },
                { name = "iron_ore", amount = 1 },
                { name = "copper_ore", amount = 1 },
                { name = "gold_ore", amount = 1 },
                { name = "diamond", amount = 1, chance = 10 }
            },
                    
            Smelting = {
                { 
                    inputs = {
                        { name = "iron_ore", amount = 5 },
                        { name = "vango", amount = 2 }
                    },
                    output = { name = "iron_ingot", amount = 1 }
                },
                { 
                    inputs = {
                        { name = "copper_ore", amount = 5 },
                        { name = "vango", amount = 2 }
                    },
                    output = { name = "copper_ingot", amount = 1 }
                },
                { 
                    inputs = {
                        { name = "gold_ore", amount = 10 },
                        { name = "vango", amount = 2 }
                    },
                    output = { name = "gold_ingot", amount = 1 }
                },
                { 
                    inputs = {
                        { name = "gold_ore", amount = 50 },
                        { name = "vango", amount = 5 }
                    },
                    output = { name = "gold_ingot", amount = 1 }
                },
            },

        },
        Messages = {
            Start      = "Vào mỏ để tiến hành đào đá!",
            GotRock    = "Bưng đá tới kho để hoàn thành nhiệm vụ",
            BackToMine = "Vào mỏ để tiến hành đào đá!",
            NeedTool   = "Bạn cần cuốc chim để đào!"
        }
    }
}
