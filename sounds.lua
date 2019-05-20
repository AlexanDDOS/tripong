local sounds = {}
sounds.sfx = {volume = 1.0}
sounds.music = {volume = 1.0}

function sounds.newSFX(path, tag)
  sounds.sfx[tag] = love.audio.newSource(path, "static")
end

function sounds.newMusic(path, tag, name, by)
  local t = {
  source = love.audio.newSource(path, "stream"),
  name = name,
  by = by
  }
  sounds.music[tag] = t
end

function sounds.setSFXVolume(volume)
  volume = volume or sounds.sfx.volume
  sounds.sfx.volume = volume
  for k, v in pairs(sounds.sfx) do
    if k ~= "volume" then
      v:setVolume(volume)
    end
  end
end

function sounds.playSFX(tag)
  local sound = sounds.sfx[tag]
  assert(sound ~= nil, string.format("sound '%s' is not loaded", tag))
  sound:play()
end

function sounds.setBGM(tag)
  local sound = sounds.music[tag]
  assert(sound ~= nil, string.format("music '%s' is not loaded", tag))
  if sounds.bgm then
    sounds.clearBGM()
  end
  sounds.bgm = sound
end

function sounds.playBGM(loop)
  loop = loop or false
  assert(sounds.bgm ~= nil, "BGM is not set")
  local sound = sounds.bgm.source
  sound:setLooping(loop)
  sound:setVolume(sounds.music.volume)
  sound:play()
end

function sounds.pauseBGM()
  loop = loop or false
  assert(sounds.bgm ~= nil, "BGM is not set")
  local sound = sounds.bgm.source
  sound:pause()
end

function sounds.stopBGM()
  loop = loop or false
  assert(sounds.bgm ~= nil, "BGM is not set")
  local sound = sounds.bgm.source
  sound:pause()
end

function sounds.clearBGM()
  loop = loop or false
  assert(sounds.bgm ~= nil, "BGM is not set")
  local sound = sounds.bgm.source
  sound:stop()
  sound:setLooping(false)
  sounds.bgm = nil
end

return sounds