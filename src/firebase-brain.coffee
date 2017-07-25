# Description:
#   A Hubot script to persist Hubot's brain using FireBase
#
# Configuration:
#   FIREBASE_BRAIN_URL - eg https://your_firebase.firebaseio.com/hubot
#   FIREBASE_BRAIN_SERVICE_PATH - Service account key file path
#
# Commands:
#   None

# Require Firebase
firebaseAdmin = require "firebase-admin"
serviceAccount = require(process.env.FIREBASE_BRAIN_SERVICE_PATH);

firebase = firebaseAdmin.initializeApp {
  credential: admin.credential.cert(serviceAccount),
  databaseURL: process.env.FIREBASE_URL
}, "hubot-firebase-brain"

# Main export
module.exports = (robot) ->

  # Do not load unless configured
  return robot.logger.warning "firebase-brain: FIREBASE_URL not set. Not attempting to load FireBase brain." unless process.env.FIREBASE_URL?

  robot.logger.info "firebase-brain: Connecting to Firebase brain at #{process.env.FIREBASE_URL} "

  # Turn off autosave until Firebase connected successfully
  robot.brain.setAutoSave false

  # expose this reference to the Robot
  robot.firebaseBrain = firebase.database()

  # Load the initial persistant brain
  robot.firebaseBrain.once 'value', (data) ->
    robot.logger.info "firebase-brain: Successfully connected to Firebase"
    robot.brain.mergeData data.val()
    robot.brain.setAutoSave true

  # As values change in Firebase load them into the local brain
  robot.firebaseBrain.on "value", (data)->
   robot.brain.mergeData data.val()
   robot.brain.save()

  # Flush brain to firebase on the 'save' event
  robot.brain.on 'save', (data = {}) ->
    sanatized_data = JSON.parse JSON.stringify(data)
    robot.firebaseBrain.set sanatized_data

  # Shutdown the brain
  robot.brain.on 'close', ->
    robot.firebaseBrain.goOffline()
