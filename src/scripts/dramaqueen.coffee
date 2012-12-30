# Description:
#   Make Hubot announce when a user enters or exits a chat room
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   hubot drama set <join|leave> message of #<room> to <message> - Announce <message> when user enters|exits the chat #<room>
#   hubot drama clear <join|leave> message of #<room> - Cancel the announcement for the chat #<room>
#   hubot drama list - List the rooms the user has messages for
#   hubot drama list for #<room> - List all the messages for the chat #<room>
#
# Author:
#   erikzaadi

module.exports = (robot) ->
  operations =
    leaving: 'leave'
    joining: 'join'
  replyToUser = (user) ->
    name:user.name
    id:user.id

  errors =
    roomEmpty: 'Error: room can not be empty..'
    messageEmpty: 'Error: message can not be empty..'

  stringNullEmptyOrOnlySpaces = (str) ->
    return not (str ? "").replace(/\s/g, "")?.length

  clearMyDrama = (response, operation) ->
    room = response.match[1]
    user = response.message.user
    replyToUser = replyToUser user

    if stringNullEmptyOrOnlySpaces room
      return response.robot.reply replyToUser, errors.roomEmpty

    if response.robot.brain.data.users[user.id]?[operation]?[room]?
      delete response.robot.brain.data.users[user.id][operation][room]
      response.robot.reply replyToUser, "#{operation} message cleared for #{room}.."
    else
      response.robot.reply replyToUser, "#{operation} message not set for #{room}.."

  setMyDrama = (response, operation) ->
    message = response.match[2]
    room = response.match[1]
    user = response.message.user
    replyToUser = replyToUser user

    if stringNullEmptyOrOnlySpaces room
      return response.robot.reply replyToUser, errors.roomEmpty

    response.robot.brain.data.users[user.id][operation] ?= []

    if stringNullEmptyOrOnlySpaces message
      response.robot.reply replyToUser, errors.messageEmpty
    else
      response.robot.brain.data.users[user.id][operation][room] = message
      response.robot.reply replyToUser, "#{operation} message at #{room} set to '#{message}'.."
  
  dramaMe = (response, operation) ->
    user = response.message.user

    if user[operation]?[user.room]?
      response.robot.messageRoom user.room, user[operation][user.room]

  listMyDrama = (response) ->
    user = response.robot.brain.data.users[response.message.user.id]
    replyToUser = {name:user.name, id:user.id}
    filterRoom = response.match[1]

    filterRoomFunc = (room, operation, user, filterRoom) ->
      ((room == filterRoom or stringNullEmptyOrOnlySpaces(filterRoom)) and user[operation][room]?)

    messages = new Array()
    for operation in [operations.joining, operations.leaving] when user[operation]?
      do (operation) ->
        for room of user[operation] when filterRoomFunc(room, operation, user, filterRoom)
          do (room) ->
            messages.push "#{operation} message of #{room}: '#{user[operation][room]}'"

    if messages.length > 0
      response.robot.reply replyToUser, messages.join('\n')
    else
      response.robot.reply replyToUser, "No messages set.." 


  robot.leave (response) =>
    dramaMe response, operations.leaving

  robot.enter (response) =>
    dramaMe response, operations.joining

  robot.respond /drama set leave of (.*) to (.*)/i, (response) =>
    setMyDrama response, operations.leaving

  robot.respond /drama set join of (.*) to (.*)/i, (response) =>
    setMyDrama response, operations.joining

  robot.respond /drama clear leave of (.*)/i, (response) =>
    clearMyDrama response, operations.leaving

  robot.respond /drama clear join of (.*)/i, (response) =>
    clearMyDrama response, operations.joining

  robot.respond /drama list room (.*)/i, (response) =>
    listMyDrama response  
  
  robot.respond /drama list all/i, (response) =>
    listMyDrama response

