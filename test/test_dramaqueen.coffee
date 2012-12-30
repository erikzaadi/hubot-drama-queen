_     = require 'underscore'
require('chai').should()

Robot = require '../node_modules/hubot/src/robot'
{TextMessage, LeaveMessage, EnterMessage} = \
  require '../node_modules/hubot/src/message'

DramaQueen = require '../src/scripts/dramaqueen'

class HelperRobot extends Robot
  constructor: ->
    super()
    @adapter = @
    @sent = []

  send: (user, strings...) ->
    strings.forEach (str) =>
      @sent.push str
    @cb? strings...

  reply: (user, strings...) ->
    strings.forEach (str) =>
      @send user, "#{user.name}: #{str}"



describe 'Drama Queen', ->
  helper = null
  dramaQueen = null

  operations =
    leaving:
      command:  'leave'
      nick:     'storming out'
      message:  LeaveMessage
    joining:
      command:  'join'
      nick:     'entering like a boss'
      message:  LeaveMessage

  testUser =
    name:     'WTF32'
    id:       123
    room:     '#LE_ROOM'

  message = 'Some Message'
  testUserInstance = null

  populateMessages = (dq, user) ->
    _.forEach operations, (op) =>
      user[dq.getKey(op.command, user.room)] = message
    user
 
  beforeEach ->
    testUserInstance = _.clone testUser
   
    helper = new HelperRobot()
    helper.brain.data.users[testUserInstance.id] = testUserInstance
    DramaQueen(helper)
    dramaQueen = helper.DramaQueen

  _.forEach operations, (operation) ->

    describe "Scheming about #{operation.nick}", ->

      it 'should set value', ->
        helper.receive new TextMessage(testUserInstance, \
          "#{helper.name} drama set #{operation.command} of #{testUserInstance.room} to #{message}")
        helper.sent.length.should.be.equal 1
        helper.sent[0].should.be.equal \
          "#{testUserInstance.name}: #{operation.command} message at #{testUserInstance.room} set to '#{message}'.."

        key = helper.DramaQueen.getKey(operation.command, testUserInstance.room)
        testUserInstance.should.have.property(key)
          .that.is.equal message

      it 'should not set value if room is missing', ->
        helper.receive new TextMessage(testUserInstance, \
          "#{helper.name} drama set #{operation.command} of  to #{message}")
        helper.sent.length.should.be.equal 1
        helper.sent[0].should.be.equal \
          "#{testUserInstance.name}: Error: room can not be empty.."

      it 'should not set value if message is missing', ->
        helper.receive new TextMessage(testUserInstance, \
          "#{helper.name} drama set #{operation.command} of #{testUserInstance.room} to ")
        helper.sent.length.should.be.equal 1
        helper.sent[0].should.be.equal \
          "#{testUserInstance.name}: Error: message can not be empty.."

     describe "Regretting about #{operation.nick}", ->

      it "should be able to clear #{operation.command} message", ->
        testUserInstance = populateMessages dramaQueen,  testUserInstance
        helper.receive new TextMessage(testUserInstance, \
          "#{helper.name} drama clear #{operation.command} of #{testUserInstance.room}")

        helper.sent.length.should.be.equal 1
        helper.sent[0].should.be.equal \
          "#{testUserInstance.name}: #{operation.command} message cleared for #{testUserInstance.room}.."

      it 'should be be notified that no message was set', ->
        helper.receive new TextMessage(testUserInstance, \
          "#{helper.name} drama clear #{operation.command} of #{testUserInstance.room}")

        helper.sent.length.should.be.equal 1
        helper.sent[0].should.be.equal \
          "#{testUserInstance.name}: #{operation.command} message not set for #{testUserInstance.room}.."

      it 'should not be able to clear if room is empty', ->
        testUserInstance = populateMessages dramaQueen,  testUserInstance
        helper.receive new TextMessage(testUserInstance, \
          "#{helper.name} drama clear #{operation.command} of  ")

        helper.sent.length.should.be.equal 1
        helper.sent[0].should.be.equal \
          "#{testUserInstance.name}: Error: room can not be empty.."
    describe "Being Dramatic when #{operation.nick}", ->

      it "should shout on #{operation.command}", ->
        testUserInstance = populateMessages dramaQueen,  testUserInstance
        helper.receive new operation.message(testUserInstance)
        helper.sent.length.should.be.equal 1
        helper.sent[0].should.be.equal message

      it "shound not shout on #{operation.command} if not set", ->
        helper.receive new operation.message(testUserInstance)
        helper.sent.length.should.be.zero

      it "shound not shout on #{operation.command} if set for another room", ->
        testUserInstance[operation.command] = []
        testUserInstance[operation.command]["#OtherRoomz"] = message
        helper.receive new operation.message(testUserInstance)
        helper.sent.length.should.be.zero


  describe "Asking to see what fuss has been set", ->
    
    it "should list all messages when asked without a room", ->
      testUserInstance = populateMessages dramaQueen,  testUserInstance
      helper.receive new TextMessage(testUserInstance, \
        "#{helper.name} drama list all")
      helper.sent.length.should.be.equal 1
      messages = [
        "leave message of #{testUserInstance.room}: '#{message}'"
        "join message of #{testUserInstance.room}: '#{message}'"
      ]
      joined = messages.join("\n")
      helper.sent[0].should.be.equal "#{testUserInstance.name}: #{joined}"

    it "should notify that there's not messages if so", ->
      helper.receive new TextMessage(testUserInstance, \
        "#{helper.name} drama list all")
      helper.sent.length.should.be.equal 1
      helper.sent[0].should.be.equal \
        "#{testUserInstance.name}: No messages set.."

    it "should filter according to room when asked with a room", ->
      testUserInstance = populateMessages dramaQueen,  testUserInstance
      testUserInstance[dramaQueen.getKey('leave', '#otherRoom')] = message
      helper.receive new TextMessage(testUserInstance, \
        "#{helper.name} drama list room #{testUserInstance.room}")
      helper.sent.length.should.be.equal 1
      helper.sent[0].should.not.contain "#otherRoom"

    it "should show no results if asked to filter for another room", ->
      testUserInstance = populateMessages dramaQueen,  testUserInstance
      testUserInstance.room = '#otherRoom'
      helper.receive new TextMessage(testUserInstance, \
        "#{helper.name} drama list room #{testUserInstance.room}")
      helper.sent.length.should.be.equal 1
      helper.sent[0].should.be.equal \
        "#{testUserInstance.name}: No messages set.."
