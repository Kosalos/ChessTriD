import UIKit
import SceneKit

// http://www.chessvariants.com/3d.dir/startrek.html

let NUM_PIECES = 32
let TOTAL_SQUARES = 64              // three static 4x4 boards; four 2x2 attack boards
let MAIN_SQUARES = 48               // three main 4x4 boards
let ATTACK_SQUARES = 4              // four 2x2 attack boards
let SQHOP = Float(2.53)             // distance between squares
let SQSIZE = CGFloat(2.3)           // square size W,L
let SQHT = CGFloat(0.1)             // square height
let SQY = Float(-0.1)
let LHT = Float(10)                 // 4x4 level height
let LHT2 = LHT / 2                  // 2x2 level offset
let xc:Float = -2 * SQHOP + SQHOP/2 // xcenter
let xs1:Float = xc + SQHOP * 3      // left,right of center
let xs2:Float = xc - SQHOP * 1
let y1:Float = -LHT * 3 / 2         // 3 main levels
let y2:Float = y1 + LHT
let y3:Float = y2 + LHT
let y1t:Float = y1 + LHT2           // Y offsets for attack boards
let y2t:Float = y2 + LHT2
let y3t:Float = y3 + LHT2
let z1:Float = -10                  // main boards front to back
let z2:Float = z1 + SQHOP * 2
let z3:Float = z2 + SQHOP * 2
let zs1f:Float = z1 - SQHOP         // offsets for attack boards
let zs1b:Float = z1 + SQHOP * 3
let zs2f:Float = z2 - SQHOP
let zs2b:Float = z2 + SQHOP * 3
let zs3f:Float = z3 - SQHOP
let zs3b:Float = z3 + SQHOP * 3

let pColorW   = "p22.png"
let pColorB   = "p10.png"

enum PieceKind : Int { case
    BP1,BP2,BP3,BP4,BP5,BP6,BP7,BP8,BC1,BC2,BR1,BR2,BB1,BB2,BQQ,BKK, // 8 pawn, 2 castle, 2 rook, 2 bishop, queen, king
    WP1,WP2,WP3,WP4,WP5,WP6,WP7,WP8,WC1,WC2,WR1,WR2,WB1,WB2,WQQ,WKK,
    NON }

struct PieceData {
    var color = Int()
    var isGlow:Bool = false
    var kind:PieceKind = .NON
    var node = SCNNode()
    
    mutating func glow(_ onOff:Bool) {
        self.isGlow = onOff
        let mat = SCNMaterial()
        mat.diffuse.contents = (color == 0) ? pColorB : pColorW
        mat.emission.contents = onOff ? UIColor(red:0.5, green:0, blue:0, alpha:0.5) : UIColor.black
        node.geometry?.materials = [mat]
    }
    
    mutating func toggleGlow() { glow(!isGlow) }
}

struct SquareData {
    var color = Int()
    var isGlow:Bool = false
    var kind:PieceKind = .NON
    var node = SCNNode()
    
    mutating func glow(_ onOff:Bool) {
        self.isGlow = onOff
        let mat = SCNMaterial()
        mat.diffuse.contents = (color == 0) ? UIColor.black : UIColor.white
        mat.emission.contents = onOff ? UIColor(red:1, green:0, blue:0, alpha:0.7) : UIColor.black
        node.geometry?.materials = [mat]
    }

    mutating func toggleGlow() { glow(!isGlow) }
}

//MARK: -

class ChessBoard {
    var piece = Array(repeating:PieceData(), count:NUM_PIECES)
    var square = Array(repeating:SquareData(), count:TOTAL_SQUARES)
    var attackBoardLocationIndex = Array(repeating:Int(), count:4)
    var isMoving:Int = 0
    let baseIndices = [ 48,52,56,60 ]     // where 2x2 boards are assigned within square storage

    
    func initialize() {
        let baseColor = "p1.png"
        let pName = [ "Pawn.dae","Castle.dae","Knight.dae","Bishop.dae","Queen.dae","King.dae" ]
        
        func daeData(_ nIndex:Int, _ colorIndex:Int) -> PieceData {
            let scn = SCNScene(named:pName[nIndex])
            let node = scn!.rootNode.childNodes[0]  // child node has the geometry
            
            scenePtr.rootNode.addChildNode(node)
            
            var p = PieceData()
            p.color = colorIndex
            p.node = node
            p.glow(false)
            
            return p
        }
        
        for p in 0 ..< NUM_PIECES {
            switch p {
            case  0 ...  7 : piece[p] = daeData(0,0)
            case  8 ...  9 : piece[p] = daeData(1,0)
            case 10 ... 11 : piece[p] = daeData(2,0)
            case 12 ... 13 : piece[p] = daeData(3,0)
            case 14        : piece[p] = daeData(4,0)
            case 15        : piece[p] = daeData(5,0)
            case 16 ... 23 : piece[p] = daeData(0,1)
            case 24 ... 25 : piece[p] = daeData(1,1)
            case 26 ... 27 : piece[p] = daeData(2,1)
            case 28 ... 29 : piece[p] = daeData(3,1)
            case 30        : piece[p] = daeData(4,1)
            case 31        : piece[p] = daeData(5,1)
            default : break
            }
        }
        
        let squareColor = [
            0,1,0,1,  1,0,1,0,  0,1,0,1,  1,0,1,0,  // 4x4
            0,1,0,1,  1,0,1,0,  0,1,0,1,  1,0,1,0,  // 4x4
            0,1,0,1,  1,0,1,0,  0,1,0,1,  1,0,1,0,  // 4x4
            0,1,1,0,    // 2x2
            0,1,1,0,    // 2x2
            0,1,1,0,    // 2x2
            0,1,1,0 ]   // 2x2
        
        for s in 0 ..< TOTAL_SQUARES {
            let sq = SCNBox(width:SQSIZE, height:SQHT, length:SQSIZE, chamferRadius:0)
            square[s].node = SCNNode(geometry:sq)
            square[s].kind = .NON
            square[s].color = squareColor[s]
            square[s].glow(false)
            
            scenePtr.rootNode.addChildNode(square[s].node)
        }
        
        // ------------------------------------------------------
        
        func addBasesUnderMainBoards() {
            let sz:CGFloat = 11.38
            let sq = SCNBox(width:sz, height:SQHT*3, length:sz, chamferRadius:1)
            sq.firstMaterial?.diffuse.contents = baseColor
            
            func addChild(_ index:Int) {
                let xzOffset = 3.7
                let base = SCNNode(geometry:sq)
                base.position = SCNVector3(xzOffset,-0.2,xzOffset)
                square[index].node.addChildNode(base)
            }
            
            let xcenter:CGFloat = 3.85
            
            func addVerticalSupport(_ index:Int,_ ht:CGFloat) {
                let sq2 = SCNBox(width:0.8, height:CGFloat(LHT2) * ht, length:1.5, chamferRadius:1)
                sq2.firstMaterial?.diffuse.contents = baseColor
                
                let base = SCNNode(geometry:sq2)
                let yOffset = -CGFloat(LHT2) * ht / 2
                base.position = SCNVector3(xcenter,yOffset,SQSIZE*11/3)
                square[index].node.addChildNode(base)
            }
            
            func addDiagonalSupport(_ index:Int) {
                let sq2 = SCNBox(width:0.6, height:CGFloat(19), length:1.5, chamferRadius:1)
                sq2.firstMaterial?.diffuse.contents = baseColor
                
                var base = SCNNode(geometry:sq2)
                base.position = SCNVector3(xcenter,2.5,13.25)

                rotateNode(&base,0.6,1,0,0)

                square[index].node.addChildNode(base)
            }
            
            addChild( 0)
            addChild(16)
            addChild(32)
            addVerticalSupport( 0,1)
            addVerticalSupport(16,3)
            addVerticalSupport(32,5)
            addDiagonalSupport(0)
        }
        
        // ------------------------------------------------------

        func addBasesUnderAttackBoards() {
            let sz = CGFloat(5.56)
            let xzOffset:CGFloat = 1.29
            let sq = SCNBox(width:sz, height:SQHT*3, length:sz, chamferRadius:1)
            sq.firstMaterial?.diffuse.contents = baseColor
            
            let sq2 = SCNBox(width:0.3, height:CGFloat(LHT2), length:0.6, chamferRadius:1)
            sq2.firstMaterial?.diffuse.contents = baseColor

            func addBaseChild(_ index:Int) {
                let base = SCNNode(geometry:sq)
                base.position = SCNVector3(xzOffset,-0.2,xzOffset)
                square[index].node.addChildNode(base)
            }

            func addVerticalSupport(_ index:Int) {
                let base = SCNNode(geometry:sq2)
                let xzOffset = SQSIZE/2
                base.position = SCNVector3(xzOffset,-CGFloat(LHT2)/2 - 0.25,xzOffset)
                square[index].node.addChildNode(base)
            }
            
            for i in 0 ..< 4 {
                addBaseChild(baseIndices[i])
                addVerticalSupport(baseIndices[i])
            }
        }
        
        // ------------------------------------------------------

        func addMainBase() {
            let sz = CGFloat(15)
            let sq = SCNBox(width:sz, height:1, length:sz, chamferRadius:1)
            sq.firstMaterial?.diffuse.contents = baseColor
            
            let base = SCNNode(geometry:sq)
            base.position = SCNVector3(0,-20,3)
            scenePtr.rootNode.addChildNode(base)
        }
        
        addMainBase()
        addBasesUnderMainBoards()
        addBasesUnderAttackBoards()
        reset()
    }
    
    //MARK: -

    func tappedNode(_ n:SCNNode) {
        for p in 0 ..< NUM_PIECES {
            if piece[p].node == n {
                piece[p].toggleGlow()
            }
        }

        for s in 0 ..< TOTAL_SQUARES {
            if square[s].node == n {
                square[s].toggleGlow()
            }
        }
    }

    func rotateNode(_ node: inout SCNNode, _ radian:Float, _ x:Float, _ y:Float, _ z:Float) {
        let orientation = node.orientation
        var glQuaternion = GLKQuaternionMake(orientation.x, orientation.y, orientation.z, orientation.w)
        let multiplier = GLKQuaternionMakeWithAngleAndAxis(radian,x,y,z)
        glQuaternion = GLKQuaternionMultiply(glQuaternion, multiplier)
        node.orientation = SCNQuaternion(x: glQuaternion.x, y: glQuaternion.y, z: glQuaternion.z, w: glQuaternion.w)
    }
    
    func update() {
        randomMovement()
        for p in piece {
            var p = p
            rotateNode(&p.node,0.005, 0,0,1)
        }
    }
    
    //MARK: -

    func reset() {
        let startingPieceLocations:[PieceKind] = [
            .WR1,.WB1,.WB2,.WR2,    // bottom
            .WP1,.WP2,.WP3,.WP4,
            .NON,.NON,.NON,.NON,
            .NON,.NON,.NON,.NON,
            .NON,.NON,.NON,.NON,    // middle
            .NON,.NON,.NON,.NON,
            .NON,.NON,.NON,.NON,
            .NON,.NON,.NON,.NON,
            .NON,.NON,.NON,.NON,    // top
            .NON,.NON,.NON,.NON,
            .BP1,.BP2,.BP3,.BP4,
            .BR1,.BB1,.BB2,.BR2,
            .WQQ,.WC1,.WP5,.WP6,    // attack 1,2  LL,LR
            .WC2,.WKK,.WP7,.WP8,
            .BP5,.BP6,.BQQ,.BC1,    // attack 3,4  UL,UR
            .BP7,.BP8,.BC2,.BKK  ]

        let base1 = SCNVector3(xc, y1, z1) // 4x4 board
        let base2 = SCNVector3(xc, y2, z2) // 4x4 board
        let base3 = SCNVector3(xc, y3, z3) // 4x4 board
        
        let startingMainSquareLocations:[SCNVector3] = [
            base1 + SCNVector3(SQHOP*0,0,SQHOP*0),    // 4x4 board
            base1 + SCNVector3(SQHOP*1,0,SQHOP*0),
            base1 + SCNVector3(SQHOP*2,0,SQHOP*0),
            base1 + SCNVector3(SQHOP*3,0,SQHOP*0),
            base1 + SCNVector3(SQHOP*0,0,SQHOP*1),
            base1 + SCNVector3(SQHOP*1,0,SQHOP*1),
            base1 + SCNVector3(SQHOP*2,0,SQHOP*1),
            base1 + SCNVector3(SQHOP*3,0,SQHOP*1),
            base1 + SCNVector3(SQHOP*0,0,SQHOP*2),
            base1 + SCNVector3(SQHOP*1,0,SQHOP*2),
            base1 + SCNVector3(SQHOP*2,0,SQHOP*2),
            base1 + SCNVector3(SQHOP*3,0,SQHOP*2),
            base1 + SCNVector3(SQHOP*0,0,SQHOP*3),
            base1 + SCNVector3(SQHOP*1,0,SQHOP*3),
            base1 + SCNVector3(SQHOP*2,0,SQHOP*3),
            base1 + SCNVector3(SQHOP*3,0,SQHOP*3),
            base2 + SCNVector3(SQHOP*0,0,SQHOP*0),    // 4x4 board
            base2 + SCNVector3(SQHOP*1,0,SQHOP*0),
            base2 + SCNVector3(SQHOP*2,0,SQHOP*0),
            base2 + SCNVector3(SQHOP*3,0,SQHOP*0),
            base2 + SCNVector3(SQHOP*0,0,SQHOP*1),
            base2 + SCNVector3(SQHOP*1,0,SQHOP*1),
            base2 + SCNVector3(SQHOP*2,0,SQHOP*1),
            base2 + SCNVector3(SQHOP*3,0,SQHOP*1),
            base2 + SCNVector3(SQHOP*0,0,SQHOP*2),
            base2 + SCNVector3(SQHOP*1,0,SQHOP*2),
            base2 + SCNVector3(SQHOP*2,0,SQHOP*2),
            base2 + SCNVector3(SQHOP*3,0,SQHOP*2),
            base2 + SCNVector3(SQHOP*0,0,SQHOP*3),
            base2 + SCNVector3(SQHOP*1,0,SQHOP*3),
            base2 + SCNVector3(SQHOP*2,0,SQHOP*3),
            base2 + SCNVector3(SQHOP*3,0,SQHOP*3),
            base3 + SCNVector3(SQHOP*0,0,SQHOP*0),    // 4x4 board
            base3 + SCNVector3(SQHOP*1,0,SQHOP*0),
            base3 + SCNVector3(SQHOP*2,0,SQHOP*0),
            base3 + SCNVector3(SQHOP*3,0,SQHOP*0),
            base3 + SCNVector3(SQHOP*0,0,SQHOP*1),
            base3 + SCNVector3(SQHOP*1,0,SQHOP*1),
            base3 + SCNVector3(SQHOP*2,0,SQHOP*1),
            base3 + SCNVector3(SQHOP*3,0,SQHOP*1),
            base3 + SCNVector3(SQHOP*0,0,SQHOP*2),
            base3 + SCNVector3(SQHOP*1,0,SQHOP*2),
            base3 + SCNVector3(SQHOP*2,0,SQHOP*2),
            base3 + SCNVector3(SQHOP*3,0,SQHOP*2),
            base3 + SCNVector3(SQHOP*0,0,SQHOP*3),
            base3 + SCNVector3(SQHOP*1,0,SQHOP*3),
            base3 + SCNVector3(SQHOP*2,0,SQHOP*3),
            base3 + SCNVector3(SQHOP*3,0,SQHOP*3) ]

        // initial square locations ----------------------
        for i in 0 ..< MAIN_SQUARES { square[i].node.position = startingMainSquareLocations[i] }
        moveAttackBoard(0, 0,false)
        moveAttackBoard(1, 1,false)
        moveAttackBoard(2,10,false)
        moveAttackBoard(3,11,false)
        
        // initial piece locations------------------------
        for s in 0 ..< TOTAL_SQUARES {
            let kind = startingPieceLocations[s]
            square[s].kind = kind
            if kind != .NON {
                let index:Int = kind.rawValue
                piece[index].node.position = square[s].node.position
            }
        }
    }
    
    func moveAttackBoard(_ who:Int, _ bIndex:Int, _ animate:Bool) {
        let baseA00 = SCNVector3(xs1, y1t, zs1f) // m1, c0   main board #1, corner 0, top
        let baseA01 = SCNVector3(xs2, y1t, zs1f) // m1, c1
        let baseA02 = SCNVector3(xs1, y1t, zs1b) // m1, c2
        let baseA03 = SCNVector3(xs2, y1t, zs1b) // m1, c3
        let baseA04 = SCNVector3(xs1, y2t, zs2f) // m2, c0   main board #2
        let baseA05 = SCNVector3(xs2, y2t, zs2f)
        let baseA06 = SCNVector3(xs1, y2t, zs2b)
        let baseA07 = SCNVector3(xs2, y2t, zs2b)
        let baseA08 = SCNVector3(xs1, y3t, zs3f) // m3, c0   main board #3
        let baseA09 = SCNVector3(xs2, y3t, zs3f)
        let baseA10 = SCNVector3(xs1, y3t, zs3b)
        let baseA11 = SCNVector3(xs2, y3t, zs3b)
        
        var baseLocations = [ baseA00,baseA01,baseA02,baseA03,baseA04,baseA05,baseA06,baseA07,baseA08,baseA09,baseA10,baseA11 ]

        let baseIndex = baseIndices[who]
        let bl = baseLocations[bIndex]
        let destinations = [
            bl + SCNVector3(SQHOP*0,0,SQHOP*0),
            bl + SCNVector3(SQHOP*1,0,SQHOP*0),
            bl + SCNVector3(SQHOP*0,0,SQHOP*1),
            bl + SCNVector3(SQHOP*1,0,SQHOP*1) ]

        for i in 0 ..< ATTACK_SQUARES {
            moveSquare(baseIndex + i, destinations[i], animate)
            
            let kind = square[baseIndex + i].kind  // also move pieces sitting on squares
            if kind != .NON {
                movePiece(kind.rawValue, destinations[i], animate)
            }
        }
        
        attackBoardLocationIndex[who] = bIndex
    }
    
    func arePiecesSameColor(_ srcIndex:Int, _ dstIndex:Int) -> Bool {
        func isWhite(_ v:PieceKind) -> Bool { return v.rawValue < 16 }
        return isWhite(square[srcIndex].kind) == isWhite(square[dstIndex].kind)
    }
    
    //MARK: -

    func moveSquare(_ index:Int, _ location:SCNVector3, _ animate:Bool) {
        if animate {
            let move = SCNAction.move(to:location, duration:0.5)
            move.timingMode = .easeInEaseOut
        
            let sequence = SCNAction.sequence([move])
        
            isMoving += 1
            square[index].node.runAction(sequence, completionHandler: { () in self.isMoving -= 1 })
        }
        else {
            square[index].node.position = location
        }
    }
    
    func movePiece(_ index:Int, _ location:SCNVector3, _ animate:Bool) {
        if animate {
            let move = SCNAction.move(to:location, duration:0.5)
            move.timingMode = .easeInEaseOut
            
            let sequence = SCNAction.sequence([move])
            
            isMoving += 1
            piece[index].node.runAction(sequence, completionHandler: { () in self.isMoving -= 1 })
        }
        else {
            piece[index].node.position = location
        }
    }
    
    func movePieceFromSquareToSquare(_ srcIndex:Int, _ dstIndex:Int) {
        if srcIndex == dstIndex { return }
        if square[srcIndex].kind == .NON { return }
    
        if square[dstIndex].kind != .NON {     // destination is not empty, or same color?
            if arePiecesSameColor(srcIndex,dstIndex) { return }
        }
    
        let pKind = square[srcIndex].kind
        square[dstIndex].kind = pKind  // logically, piece has already moved
        square[srcIndex].kind = .NON
    
        let m1 = square[srcIndex].node.position + SCNVector3(0,0.6,0)   // above src position
        let m2 = m1 + SCNVector3(0,0,-6)                                // out to safe area
        let m5 = square[dstIndex].node.position                         // final dest
        let m4 = m5 + SCNVector3(0,0.6,0)                               // above dest position
        let m3 = m4 + SCNVector3(0,0,-6)                                // safe area opposite destination
        
        let speed:Double = 0.3
        let move1 = SCNAction.move(to:m1, duration:0.2)
        let move2 = SCNAction.move(to:m2, duration:speed)
        let move3 = SCNAction.move(to:m3, duration:speed + speed * Double(abs(square[srcIndex].node.position.y - square[dstIndex].node.position.y) / LHT))
        let move4 = SCNAction.move(to:m4, duration:speed)
        let move5 = SCNAction.move(to:m5, duration:0.2)

        move2.timingMode = .easeInEaseOut
        move3.timingMode = .easeInEaseOut
        move4.timingMode = .easeInEaseOut

        let sequence = SCNAction.sequence([move1,move2,move3,move4,move5])
        
        isMoving += 1
        piece[pKind.rawValue].node.runAction(sequence, completionHandler: { () in self.isMoving -= 1 })
    }
    
    //MARK: -

    func randomMovement() {
        func iRandom(_ min:Int, _ max:Int) -> Int { // inclusive
            if min == max { return 0 }
            return min + Int(arc4random()) % (1 + max - min)
        }
        
        if isMoving > 0 { return }
        
        if iRandom(0,10) < 2 {     // move random attack board to random location
            let index = iRandom(0,3)    // which board to move
            var destIndex:Int = 0       // destination position
            
            while true {
                destIndex = iRandom(0,11)
                var unusedLocation = true
                for i in 0 ..< ATTACK_SQUARES { if attackBoardLocationIndex[i] == destIndex { unusedLocation = false }}
                
                if unusedLocation { break }
            }
            
            moveAttackBoard(index,destIndex,true)
        }
        else {                    // move random piece to random empty square
            while true {
                let srcIndex = iRandom(0,TOTAL_SQUARES-1) // random source square

                if square[srcIndex].kind != .NON {    // have piece in source square
                    let dstIndex = iRandom(0,TOTAL_SQUARES-1)  // destination square

                    if srcIndex != dstIndex && square[dstIndex].kind == .NON { // a move could be made
                        movePieceFromSquareToSquare(srcIndex,dstIndex)
                        return
                    }
                }
            }
        }
    }
}

//MARK: -

extension SCNVector3 {
    static func + (left: SCNVector3, right: SCNVector3) -> SCNVector3 {
        var ans = left
        ans.x += right.x
        ans.y += right.y
        ans.z += right.z
        return ans
    }
}

