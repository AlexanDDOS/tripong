--Asset & settings definition file
--Define new asset here, if it doesn't cause a game crash while loading a module in main.lua
--The file is loaded by dofile() in main.lua after adding modules to states.commonModules

--INPUT DEFINITION
input.addMenuAction("menu_up", {"up", "w"}, "1_u", "-lefty")
input.addMenuAction("menu_down", {"down", "s"}, "1_d", "lefty")
input.addMenuAction("menu_right", {"right", "d"}, "1_r", "leftx")
input.addMenuAction("menu_left", {"left", "a"}, "1_l", "-leftx")
input.addMenuAction("menu_select", {"return", "space"}, "1_r", "leftx")

input.addAction("move_up", {"KEY_w", "KEY_i", "KEY_right"})
input.addAction("move_down", {"KEY_a", "KEY_l", "KEY_left"})
input.addAction("pause", {"KEY_escape", "KEY_escape", "KEY_escape"})

--INITIAL COMMON VARIABLE DEFINITION
states.common.score = {0, 0, 0}
states.common.playerColors = {
  {1, 0, 0},
  {0, 1, 0},
  {0, 0, 1}
}

--FONT DEFINITION
fonts.add("assets/fonts/ledfont.otf", "score", 48)
fonts.add("assets/fonts/Monoid-Regular.ttf", "label", 48)

--SOUND DEFINITION
sounds.newSFX("assets/sfx/goal.wav", "goal")
sounds.newSFX("assets/sfx/reflection.wav", "reflection")
sounds.newSFX("assets/sfx/m_move.wav", "m_move")
sounds.newSFX("assets/sfx/m_select.wav", "m_select")