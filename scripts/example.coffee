# A little helper class to convert timestamp diffs into more readable messages.
class ReadableTimeDiff
  constructor: (@timestamp) ->

  # Converts the difference between the timestamps to a readable format.
  toString: ->
    lookup = { weeks: 604800, days: 86400, hours: 3600, minutes: 60, seconds: 1 }
    result = []
    diff = ((new Date).getTime() - @timestamp) / 1000 # milliseconds -> seconds
    for label, value of lookup
      units = parseInt(diff / value)
      diff -= units * value
      result.push("#{units} #{label}") if units > 0
    result.join(', ')

# Provides helper methods for dealing with checkouts.
class Checkouts
  constructor: (@robot) ->
    @features = @robot.brain.get('featuresv2') || {}

  persist: ->
    @robot.brain.set('featuresv2', @features)

  # Simple setter, no logic.
  set: (which, who) ->
    @features[which] = {
      who: who,
      when: (new Date).getTime()
    }

  delete: (which) ->
    delete @features[which]

  get: (which) ->
    @features[which]

  who: (which) ->
    (@get(which) || {})['who']

  when: (which) ->
    (@get(which) || {})['when']

  # Hubot is stuck at CoffeeScript 1.6.3, so no generators D:
  each: (callback) ->
    for key, value of @features
      callback(key, value)

  # Temporary method to ensure all the values are migrated to hashes. After this
  # runs once, it should be removed. Hubot doesn't support migrations...
  migrate: (res) ->
    if @robot.brain.get('featuresv2')
      return res.send "Cannot migrate, `featuresv2` is populated! :scream:"

    legacy = @robot.brain.get('features') || {}
    for key, value of legacy
      if typeof value is 'string'
        @set(key, value)
        res.send ":white_check_mark: {`#{key}` => `#{value}`}"
      else
        res.send ":negative_squared_cross_mark: key `#{key}`, value `#{value}`"
    @persist()

# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md
module.exports = (robot) ->
  robot.hear /badger/i, (res) ->
    res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"

  robot.respond /open the (.*) doors/i, (res) ->
    doorType = res.match[1]
    if doorType is "pod bay"
      res.reply "I'm afraid I can't let you do that."
    else
      res.reply "Opening #{doorType} doors"

  robot.hear /I like pie/i, (res) ->
    res.emote "makes a freshly baked pie"

  lulz = ['lol', 'rofl', 'lmao']

  robot.respond /lulz/i, (res) ->
    res.send res.random lulz

  robot.topic (res) ->
    res.send "#{res.message.text}? That's a Paddlin'"


  enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  leaveReplies = ['Are you still there?', 'Target lost', 'Searching']

  robot.enter (res) ->
    res.send res.random enterReplies
  robot.leave (res) ->
    res.send res.random leaveReplies

  answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING

  robot.respond /what is the answer to the ultimate question of life/, (res) ->
    unless answer?
      res.send "The number 42 is, in The Hitchhiker's Guide to the Galaxy by Douglas Adams, 'The Answer to the Ultimate Question of Life, the Universe, and Everything', calculated by an enormous supercomputer over a period of 7.5 million years. Unfortunately, no one knows what the question is. Thus, to calculate the Ultimate Question, a special computer the size of a small planet was built from organic components and named 'Earth'. This appeared first in the radio play and later in the novelization of The Hitchhiker's Guide to the Galaxy. The fact that Adams named the episodes of the radio play 'fits', the same archaic title for a chapter or section used by Lewis Carroll in 'The Hunting of the Snark', suggests that Adams was influenced by Carroll's fascination with and frequent use of the number. The fourth book in the series, the novel So Long, and Thanks for All the Fish, contains 42 chapters. According to the novel Mostly Harmless, 42 is the street address of Stavromula Beta. In 1994 Adams created the 42 Puzzle, a game based on the number 42. The phrase 'the answer to life, the universe and everything is' has exactly 42 characters, including the comma after 'life'."
      return
    res.send "#{answer}, but what is the question?"

  robot.respond /you are a little slow/, (res) ->
    setTimeout () ->
      res.send "Who you calling 'slow'?"
    , 60 * 1000

  annoyIntervalId = null

  robot.respond /annoy me/, (res) ->
    if annoyIntervalId
      res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
      return

    res.send "Hey, want to hear the most annoying sound in the world?"
    annoyIntervalId = setInterval () ->
      res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
    , 1000

  robot.respond /unannoy me/, (res) ->
    if annoyIntervalId
      res.send "GUYS, GUYS, GUYS!"
      clearInterval(annoyIntervalId)
      annoyIntervalId = null
    else
      res.send "Not annoying you right now, am I?"


  robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
    room   = req.params.room
    data   = JSON.parse req.body.payload
    secret = data.secret

    robot.messageRoom room, "I have a secret: #{secret}"

    res.send 'OK'

  robot.error (err, res) ->
    robot.logger.error "DOES NOT COMPUTE"

    if res?
      res.reply "DOES NOT COMPUTE"

  robot.respond /have a soda/i, (res) ->
    # Get number of sodas had (coerced to a number).
    sodasHad = robot.brain.get('totalSodas') * 1 or 0

    if sodasHad > 4
      res.reply "I'm too fizzy.."

    else
      res.reply 'Sure!'

      robot.brain.set 'totalSodas', sodasHad+1

  robot.respond /sleep it off/i, (res) ->
    robot.brain.set 'totalSodas', 0
    res.reply 'zzzzz'

  robot.respond /Goodnight/i, (res) ->
    res.reply 'Goodnight!!'

  robot.respond /are you sleepy/i, (res) ->
    res.reply 'Not really.. you humans sleep.. i am AUTOBOT!!'

  robot.respond /wake me up when september ends/i, (res) ->
    res.reply 'Deployyyyyyy....... to production :D'

  robot.respond /migrate features/, (res) ->
    res.send "Migrating to the new DB format (key `featuresv2`)..."
    (new Checkouts(robot)).migrate(res)
    res.send "Completed migration :tayne:"

  robot.respond /who checked out (.*)\??/i, (res) ->
    feature = res.match[1]
    res.send "#{new Checkouts(robot).who(feature)} checked out #{feature}"

  robot.respond /show checkouts/i, (res) ->
    result = ':realtor: CORE WEB FEATURE BOXES :realtor: \n\n'

    if robot.brain.get('featuresv2')
      (new Checkouts(robot)).each (feature, meta) =>
        since = (new ReadableTimeDiff(meta['when'])).toString()
        result += "> *#{meta['who']}* checked out *#{feature}* for #{since}\n"
    else
      for feature, name of robot.brain.get('features')
        result += "> *#{name}* checked out *#{feature}*\n"

    result += "\n\n> Any *feature* not listed is free for the taking! :parrotcop:"
    res.send result

  robot.respond /nuke (feature )?(.*)/i, (res) ->
    user = res.message.user.name
    feature = res.match[2]
    checkouts = new Checkouts(robot)

    if !checkouts.get(feature)
      return res.send "Hey, #{user}, #{feature} doesn't exist..."

    checked_out = checkouts.who(feature) || 'nobody'

    if 'nobody' == checked_out || user == checked_out
      checkouts.delete(feature)
      checkouts.persist()
      res.send "Nuked #{feature} from orbit :nuke:"
    else
      res.send "#{user} has checked out that feature, make them give it up first (or steal it)!"

  robot.respond /steal (.*)/i, (res) ->
    user = res.message.user.name
    feature = res.match[1]
    checkouts = new Checkouts(robot)
    checked_out = checkouts.who(feature)

    if checked_out?
      checkouts.set(feature, user)
      checkouts.persist()

      res.send "Hey, @#{checked_out}, @#{user} stole #{feature} from you :feelsgood:"
    else
      res.send "#{user} tried to steal something that doesn't exist :jimminy_cricket:"

  robot.respond /check\s?out (.*)/i, (res) ->
    user = res.message.user.name
    feature = res.match[1]
    checkouts = new Checkouts(robot)
    checked_out = checkouts.who(feature) || 'nobody'

    if 'nobody' == checked_out
      checkouts.set(feature, user)
      res.send "#{feature} is all yours!"
    else
      if checked_out == user
        checkouts.set(feature, 'nobody')
        res.send "#{feature} is now free for the taking!"
      else
        res.send "Sorry, #{checked_out} already checked out #{feature}."

    checkouts.persist()
