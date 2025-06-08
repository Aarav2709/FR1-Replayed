-- utils/audio.lua
-- Audio Management System

local M = {}

-- Audio channels
M.musicChannel = 1
M.sfxChannel = 2

-- Audio objects
M.music = {}
M.sounds = {}

-- Load audio files
function M.loadAudio()
    -- Music
    M.music.menu = audio.loadStream("assets/audio/music/menu_theme.mp3")
    M.music.game = audio.loadStream("assets/audio/music/game_theme.mp3")
    M.music.victory = audio.loadStream("assets/audio/music/victory.mp3")
    
    -- Sound effects
    M.sounds.jump = audio.loadSound("assets/audio/sfx/jump.wav")
    M.sounds.powerup = audio.loadSound("assets/audio/sfx/powerup.wav")
    M.sounds.explosion = audio.loadSound("assets/audio/sfx/explosion.wav")
    M.sounds.coin = audio.loadSound("assets/audio/sfx/coin.wav")
    M.sounds.button = audio.loadSound("assets/audio/sfx/button.wav")
    M.sounds.whoosh = audio.loadSound("assets/audio/sfx/whoosh.wav")
end

-- Play music
function M.playMusic(musicName, options)
    options = options or {}
    options.channel = M.musicChannel
    options.loops = options.loops or -1 -- Loop by default
    
    if M.music[musicName] then
        audio.play(M.music[musicName], options)
    end
end

-- Stop music
function M.stopMusic()
    audio.stop(M.musicChannel)
end

-- Play sound effect
function M.playSound(soundName, options)
    options = options or {}
    options.channel = M.sfxChannel
    
    if M.sounds[soundName] then
        audio.play(M.sounds[soundName], options)
    end
end

-- Set music volume
function M.setMusicVolume(volume)
    audio.setVolume(volume, { channel = M.musicChannel })
end

-- Set SFX volume
function M.setSFXVolume(volume)
    audio.setVolume(volume, { channel = M.sfxChannel })
end

-- Cleanup
function M.cleanup()
    audio.stop()
    
    -- Dispose music
    for name, music in pairs(M.music) do
        audio.dispose(music)
        M.music[name] = nil
    end
    
    -- Dispose sounds
    for name, sound in pairs(M.sounds) do
        audio.dispose(sound)
        M.sounds[name] = nil
    end
end

-- Initialize audio system
function M.init()
    audio.reserveChannels(2) -- Reserve channels for music and SFX
    M.loadAudio()
end

return M
