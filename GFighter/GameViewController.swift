//
//  GameViewController.swift
//  GFighter
//
//  Created by Santo Gaglione on 20/02/22.
//

import UIKit
import QuartzCore
import SceneKit

class GameViewController: UIViewController {
    
    
    var scnView: SCNView!
    var scnScene: SCNScene!
    var cameraNode: SCNNode!
    var spawnTime: TimeInterval = 0
    
    //Access to GameHelper
    var game = GameHelper.sharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupView()
        setupScene()
        setupCamera()
        //spawnShape()
        setupHUD()
        
    } //End viewDidLoad

    override var shouldAutorotate: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func setupView() {
        scnView = self.view as! SCNView
        scnView.showsStatistics = false
        scnView.allowsCameraControl = false
        scnView.autoenablesDefaultLighting = true
        scnView.delegate = self
        scnView.isPlaying = true
    } //End func setupView
    
    func setupScene() {
        scnScene = SCNScene()
        scnView.scene = scnScene
        scnScene.background.contents = "GeometryFighter.scnassets/Textures/Background_Diffuse.jpg"
    } //End func setupScene
    
    func setupCamera() {
        cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        cameraNode.position = SCNVector3(x: 0, y: 5, z: 10)
        scnScene.rootNode.addChildNode(cameraNode)
        
    } //End func setupCamera
    
    func spawnShape() {
        var geometry: SCNGeometry
        
//        Switch case delle forme che possono spawnare
        switch ShapeType.random() {
            
        case .Box: geometry = SCNBox(width: 0.5, height: 0.5, length: 0.5, chamferRadius: 0.0)
        case .Sphere: geometry = SCNSphere(radius: 0.5)
        case .Pyramyd: geometry = SCNPyramid(width: 0.5, height: 0.5, length: 0.5)
        case .Torus: geometry = SCNTorus(ringRadius: 0.5, pipeRadius: 0.5)
        case .Capsule: geometry = SCNCapsule(capRadius: 0.5, height: 0.5)
        case .Cylinder: geometry = SCNCylinder(radius: 0.5, height: 0.5)
        case .Cone: geometry = SCNCone(topRadius: 0.5, bottomRadius: 0.5, height: 0.5)
        case .Tube: geometry = SCNTube(innerRadius: 0.5, outerRadius: 0.5, height: 0.5)
            
        } //End switch
        
        //Colors
        let color = UIColor.random()
        geometry.materials.first?.diffuse.contents = color

        //Create node with shapes
        let geometryNode = SCNNode(geometry: geometry)
        geometryNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)

        //Add force to node
        let randomX = Float.random(min: -2, max: 2)
        let randomY = Float.random(min: 10, max: 18)
        let force = SCNVector3(x: randomX, y: randomY, z: 0)
        let position = SCNVector3(x: 0.05, y: 0.05, z: 0.05)
        geometryNode.physicsBody?.applyForce(force, at: position, asImpulse: true)
        
        let trailEmitter = createTrail(color: color, geometry: geometry)
        geometryNode.addParticleSystem(trailEmitter)
        
        //All that is not black is GOOD, used to name the spawned objects in order to identify them
        
        if color == UIColor.black {
            geometryNode.name = "BAD"
        } else {
            geometryNode.name = "GOOD"
        }
        
        scnScene.rootNode.addChildNode(geometryNode)
        
    } // End func spawnShape
    
    func cleanScene() {
        for node in scnScene.rootNode.childNodes {
            if node.presentation.position.y < -2 {
                node.removeFromParentNode()
            }
        }
    }
    
    // Create Trail
    func createTrail(color: UIColor, geometry: SCNGeometry) -> SCNParticleSystem {
        let trail = SCNParticleSystem(named: "Trail.scnp", inDirectory: nil)!
        trail.particleColor = color
        trail.emitterShape = geometry
        return trail
    } // End func createTrail
    
    func setupHUD() {
        game.hudNode.position = SCNVector3(x: 0.0, y: 9.5, z: 0.0)
        scnScene.rootNode.addChildNode(game.hudNode)
    } //End func setupHUD called from Game Helper
    
    
    // Function to check which node was touched, if the good or the bad, and handles the game score and lives
    func handleTouchFor(node: SCNNode) {
        if node.name == "GOOD" {
            game.score += 1
            node.removeFromParentNode()
        } else if node.name == "BAD" {
            game.lives -= 1
            
        }
        
        
    } // End func handleTouchFor
    
    // Handles Touch
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //Grab first touch
        let touch = touches.first
        //Identify touch on location
        let location = touch!.location(in: scnView)
        //Check for hit and if hit take the firs
        let hitResults = scnView.hitTest(location, options: nil)
        
        //If the result of the touch is called HUD don't do anything, if is anything else handle the touch with the instructions given 
        if let result = hitResults.first {
            if result.node.name == "HUD" {
                return
                } else {
            //Pass the hit to the touch handler for the score or the life decreasement
                    handleTouchFor(node: result.node)
                    
                }
            
            createExplosion(geometry: result.node.geometry!,
                position: result.node.presentation.position,
                rotation: result.node.presentation.rotation)
                result.node.removeFromParentNode()
        }
        
    } // End func touchesBegan
    
    // Create explosion
    func createExplosion(geometry: SCNGeometry, position: SCNVector3, rotation: SCNVector4) {
        let explosion = SCNParticleSystem(named: "Explosion.scnp", inDirectory: nil)!
        explosion.emitterShape = geometry
        explosion.birthLocation = .surface
        let rotationMatrix = SCNMatrix4MakeRotation(rotation.w, rotation.x, rotation.y, rotation.z)
        let translationMatrix = SCNMatrix4MakeTranslation(position.x, position.y, position.z)
        let transformMatrix = SCNMatrix4Mult(rotationMatrix, translationMatrix)
        scnScene.addParticleSystem(explosion, transform: transformMatrix)
    }
    
} // End GameViewController: UIViewController


// Extension al GameViewController per RenderDelegate

extension GameViewController: SCNSceneRendererDelegate {
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time:
                  TimeInterval) {
        if time > spawnTime {
        spawnShape()
            
        spawnTime = time + TimeInterval(Float.random(min: 0.2, max: 1.5))
    }
        
        cleanScene()
        game.updateHUD()
        
} // End Extension al GameViewController
}
