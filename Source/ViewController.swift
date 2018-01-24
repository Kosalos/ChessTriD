import UIKit
import SceneKit

var scenePtr:SCNScene!

class ViewController: UIViewController,SCNSceneRendererDelegate {
    var timer = Timer()
    var chessBoard = ChessBoard()
    var scnView:SCNView! = nil

    var light:SCNNode!
    var lightAngle:Float = 0

    override var shouldAutorotate: Bool { return true }
    override var prefersStatusBarHidden: Bool { return true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { return .all }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        scenePtr = SCNScene()        
        scnView = self.view as! SCNView
        
        scnView.backgroundColor = UIColor(red:0.1, green:0.1, blue:0.1, alpha:1.0)
        scnView.autoenablesDefaultLighting = true
        scnView.allowsCameraControl = true
        scnView.delegate = self
        scnView.scene = scenePtr
        
        // Camera
        let camera = SCNCamera()
        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = SCNVector3(x:-15.5976, y:10.0997, z:-23.9022)
        cameraNode.rotation = SCNVector4(x:0.0722687, y:0.969533, z:0.234056, w:3.72333)
        cameraNode.orientation = SCNQuaternion(x: 0.069233, y: 0.928808, z:0.224225, w:-0.286784)
        scenePtr.rootNode.addChildNode(cameraNode)

        chessBoard.initialize()

//        // Floor
//        let myFloor = SCNFloor()
//        myFloor.reflectivity = 1
//        let myFloorNode = SCNNode(geometry: myFloor)
//        myFloorNode.position = SCNVector3(x: 0, y: -21, z: 0)
//        scenePtr.rootNode.addChildNode(myFloorNode)

        setupLights()
     
        timer = Timer.scheduledTimer(timeInterval: 0.01, target:self, selector: #selector(ViewController.timerHandler), userInfo: nil, repeats:true)
    }
    
    func setupLights() {
//        let light = SCNLight()
//        light.type = SCNLight.LightType.spot
//        light.spotInnerAngle = 5 // 30.0
//        light.spotOuterAngle = 160 // 80.0
//        light.castsShadow = true
//        let lightNode = SCNNode()
//        lightNode.light = light
//        lightNode.position = SCNVector3(x:0, y:24, z:0)
//        scenePtr.rootNode.addChildNode(lightNode)

        let ambientLight = SCNLight()
        ambientLight.type = SCNLight.LightType.ambient
        ambientLight.color = UIColor.darkGray
        ambientLight.zFar = 500
        let ambientLightNode = SCNNode()
        ambientLightNode.name = "AmbientLight"
        ambientLightNode.light = ambientLight
        ambientLightNode.castsShadow = true
        scenePtr.rootNode.addChildNode(ambientLightNode)

        let omniLight = SCNLight()
        omniLight.type = SCNLight.LightType.omni
        omniLight.color = UIColor.lightGray // white
        omniLight.orthographicScale = 25
        let omniLightNode = SCNNode()
        omniLightNode.name = "OmniLight"
        omniLightNode.light = omniLight
        omniLightNode.position = SCNVector3(x: -30.0, y: 100, z: 40.0)
        omniLightNode.castsShadow = false
        scenePtr.rootNode.addChildNode(omniLightNode)
    }
    
    @objc func timerHandler() {
        chessBoard.update()
    }
    
    @IBAction func tappedTwice(_ sender: UITapGestureRecognizer) {
        chessBoard.reset()
        
        //        let pv = scnView.pointOfView!
        //        Swift.print("Camera position ", pv.position.x, pv.position.y, pv.position.z)
        //        Swift.print("Camera rotation ", pv.rotation.x, pv.rotation.y, pv.rotation.z, pv.rotation.w);
        //        Swift.print("Camera orientation ", pv.orientation.x, pv.orientation.y, pv.orientation.z, pv.orientation.w);
    }
    
    @IBAction func tappedOnce(_ sender: UITapGestureRecognizer) {
        let pt = sender.location(in: scnView)
        let hitResults = scnView.hitTest(pt, options: [:])

        if hitResults.count > 0 {
            chessBoard.tappedNode(hitResults[0].node)
        }
    }

}
