/// Determines the object type to describe and configure the Augmented Reality techniques to be used in an ARSession.
enum ArConfiguration {
  /// A configuration for running world tracking.
  /// World tracking provides 6 degrees of freedom tracking of the device.
  /// By finding feature points in the scene, world tracking enables performing hit-tests against the frame.
  /// Tracking can no longer be resumed once the session is paused.
  worldTracking,

  // TODO [smuravev] Here, we disable code related on Apple TrueDepth API (because currently not used).
  //                 Do not enable it until we really start using it (otherwise Apple rejects validation in AppStore):
  //                 Here is what Apple requests to solve:
  //                 --
  //                 We have started the review of your app, but we are not able to continue because we need additional information about how your app uses information collected by the TrueDepth API.
  //                 To help us proceed with the review of your app, please provide complete and detailed information to the following questions.
  //                 What information is your app collecting using the TrueDepth API?
  //                 For what purposes are you collecting this information? Please provide a complete and clear explanation of all planned uses of this data.
  //                 Will the data be shared with any third parties? Where will this information be stored?
  //                 --
  //
  // /// A configuration for running image tracking.
  // /// Image tracking provides 6 degrees of freedom tracking of known images. Four images may be tracked simultaneously.
  // imageTracking,
  //
  // /// A configuration for running face tracking.
  // /// Face tracking uses the front facing camera to track the face in 3D providing details on the topology and expression of the face.
  // /// A detected face will be added to the session as an ARFaceAnchor object which contains information about head pose, mesh, eye pose, and blend shape
  // /// coefficients. If light estimation is enabled the detected face will be treated as a light probe and used to estimate the direction of incoming light.
  // faceTracking,
  //
  // /// A configuration for running body tracking.
  // /// Body tracking provides 6 degrees of freedom tracking of a detected body in the scene.
  // bodyTracking,
}
