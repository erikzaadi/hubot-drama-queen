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
#   hubot drama set <join|leave> of #<room> to <message> - Announce <message> when user enters|exits the chat #<room>
#   hubot drama add <join|leave> of #<room> to <message> - Add an announcement (<message>) when user enters|exits the chat #<room>
#   hubot drama clear <join|leave> of #<room> - Cancel the announcement for the chat #<room>
#   hubot drama delete <join|leave> of #<room> at index <index> - Cancel <index>th announcement for the chat #<room>
#   hubot drama delete <join|leave> of #<room> where <message> - Cancel the announcement for the chat #<room> where the message is <message>
#   hubot drama list all - List the rooms the user has messages for
#   hubot drama list room #<room> - List all the messages for the chat #<room>
#
# Author:
#   erikzaadi
#
#

module.exports = (robot) ->

  robot.DramaQueen = new DramaQueen(robot)
  robot.DramaQueenClass = DramaQueen


class DramaQueen
  constructor: (@robot) ->
    @robot.leave (response) =>
      @dramaMe response, @operations.leaving

    @robot.enter (response) =>
      @dramaMe response, @operations.joining

    @robot.respond /drama set (leave|join) of (.*) to (.*)/i, (response) =>
      @setMyDrama response

    @robot.respond /drama add (leave|join) of (.*) to (.*)/i, (response) =>
      @addToMyDrama response

    @robot.respond /drama clear (leave|join) of (.*)/i, (response) =>
      @clearMyDrama response

    @robot.respond /drama delete (leave|join) of (.*) at index (\d)/i, \
    (response) =>
      @clearMyTramaAt response

    @robot.respond /drama delete (leave|join) of (.*) where (.*)/g, \
    (response) =>
      @clearMyDramaWhere response

    @robot.respond /drama list room (.*)/i, (response) =>
      @listMyDramaAtRoom response
    
    @robot.respond /drama list all/i, (response) =>
      @listAllMyDrama response

  operations:
    leaving: 'leave'
    joining: 'join'

  getReplyToUser: (user) ->
    name:user.name
    id:user.id

  getUser: (user) ->
    if user.id?
      @robot.userForId user.id
    else
      @robot.userForName user.name

  errors:
    roomEmpty: 'Error: room can not be empty..'
    messageEmpty: 'Error: message can not be empty..'

  stringNullEmptyOrOnlySpaces: (str) ->
    return not (str ? "").replace(/\s/g, "")?.length

  isArray:
    Array.isArray || ( value ) -> \
    return {}.toString.call( value ) is '[object Array]'

  startswith: (str, val) ->
    str.indexOf(val) == 0

  separator: "<DRAMA-LIKE-A-BOSS>"
  prefix : "__DRAMAQUEEN__"

  getKey: (operation, room) ->
    "#{@prefix}#{operation}#{@separator}#{room}"

  keyToValues: (key, val) ->
    str = key.replace(@prefix, "")
    splitted = str.split(@separator)

    toReturn =
      operation:  splitted[0]
      room:       splitted[1]
      message:    val

    toReturn

  getValues: (user, operation, room) ->
    key = @getKey operation, room
    if not user[key]?
      return []

    splitted = user[key].split(@separator)

    return splitted

  getAllValues: (user) ->
    vals = for key, val of user when @startswith(key, @prefix)
      @keyToValues(key, val)
    vals ? []
    
  getRandomValue: (user, operation, room) ->
    values = @getValues(user, operation, room)
    return null if values.length == 0
    return values[0] if values.length == 1
    index = Math.round(Math.random() * values.length)
    values[index]

  addValueAndGetUpdated: (user, operation, room, message) ->
    values = @getValues user, operation, room
    values.push message if message not in values
    values

  saveValues: (user, operation, room, values) ->
    user[@getKey(operation, room)] = values.join @separator
    @robot.brain.save()

  removeMessageByIndex: (values, index) ->
    values.splice(index + 1, 1)
    values

  removeMessageByContent: (values, message) ->
    value for value in values when value != message

  clearMyTramaAt: (response) ->
    return

  clearMyDramaWhere: (response) ->
    return

  clearMyDrama: (response, filterFcn) ->
    filterFcn ?= (value) ->
      true
    operation = response.match[1]
    room = response.match[2]
    user = @getUser response.message.user
    replyToUser = @getReplyToUser user

    if @stringNullEmptyOrOnlySpaces(room)
      return @robot.reply replyToUser, @errors.roomEmpty

    values = @getValues user, operation, room
    
    length = values.length
    for value in values when filterFcn(value)
      values = @removeMessageByContent values, value

    if values.length == length
      return @robot.reply replyToUser, \
         "#{operation} message not set for #{room}.."

    @saveValues user, operation, room, values
    @robot.reply replyToUser, "#{operation} message cleared for #{room}.."

  addOrSave: (response, valuesFcn) ->
    operation = response.match[1]
    room = response.match[2]
    message = response.match[3]
    user = @getUser response.message.user
    replyToUser = @getReplyToUser user

    if @stringNullEmptyOrOnlySpaces room
      return @robot.reply replyToUser, @errors.roomEmpty

    if @stringNullEmptyOrOnlySpaces message
      @robot.reply replyToUser, @errors.messageEmpty
    else
      valuesFcn user, operation, room, message
      @robot.brain.save()
      @robot.reply replyToUser, \
        "#{operation} message at #{room} set to '#{message}'.."
 
  setMyDrama: (response) ->
    @addOrSave response, (user, operation, room, message) =>
      @saveValues user, operation, room, [message]

  addToMyDrama: (response) ->
    @addOrSave response, (user, operation, room, message) =>
      @saveValues user, operation, room, @addValueAndGetUpdated(message)
  
  dramaMe: (response, operation) ->
    user = @getUser response.message.user
    value = @getRandomValue(user, operation, user.room)

    @robot.messageRoom(user.room, value) if value

  listMyDrama: (response, filterFcn) ->
    user = @getUser response.message.user
    replyToUser = @getReplyToUser user
    messages = new Array()

    allValues = @getAllValues user

    for value in allValues
      do (value) =>
        if filterFcn(user, value.operation, value.room)
          key = @getKey value.operation, value.room
          messages.push "#{value.operation} message of #{value.room}: '#{user[key]}'"

    if messages.length > 0
      @robot.reply replyToUser, messages.join('\n')
    else
      @robot.reply replyToUser, "No messages set.."

  listAllMyDrama: (response) ->
    @listMyDrama response, (user, operation, room) ->
      true

  listMyDramaAtRoom: (response) ->
    filterRoom = response.match[1]
    @listMyDrama response, (user, operation, room) =>
      room == filterRoom or @stringNullEmptyOrOnlySpaces(filterRoom)

