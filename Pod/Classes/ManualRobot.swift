public class ManualRobot : Robot {
    let asyncQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    
    override public init(endpoint : String, namespace: String){
        super.init(endpoint: endpoint, namespace: namespace)
    }
    
    override public func initialize(playerName : String){
        super.initialize(playerName)
    }
    
    public func move(dir : RobotDir, callback:((result: Bool, error: ErrorType?) -> Void )?){
        dispatch_async(self.asyncQueue){data in
            do {
                let res = try super.move(dir)
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: res, error: nil)
                })
            }
            catch let error {
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: false, error: error)
                })
            }
        }
    }
    
    public func look(dir: RobotDir, callback:((result: (item: RobotItem, distance: Int), error: ErrorType?) -> Void )?){
        dispatch_async(self.asyncQueue){data in
            do {
                let res = try super.look(dir)
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: res, error: nil)
                })
            }
            catch let error {
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: (item: .Empty, distance: 0), error: error)
                })
            }
        }
    }
    
    public func fire(dir: RobotDir, callback:((result: Bool, error: ErrorType?) -> Void )?){
        dispatch_async(self.asyncQueue){data in
            do {
                let res = try super.fire(dir)
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: res, error: nil)
                })
            }
            catch let error {
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: false, error: error)
                })
            }
        }
    }

    public func getPosition(callback:((result:(x:Int, y:Int), error: ErrorType?) -> Void )?){
        dispatch_async(self.asyncQueue){data in
            do {
                let res = try super.getPosition()
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: res, error: nil)
                })
            }
            catch let error {
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: (x:0, y:0), error: error)
                })
            }
        }
    }
    
    public func teleport(){
        self.teleport(nil)
    }
    
    public func teleport(callback:((result:(x:Int, y:Int), error: ErrorType?) -> Void )?){
        dispatch_async(self.asyncQueue){data in
            do {
                let res = try super.teleport()
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: res, error: nil)
                })
            }
            catch let error {
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: (x:0, y:0), error: error)
                })
            }
        }
    }

    public func getBattery(callback:((result: Int, error: ErrorType?) -> Void )?){
        dispatch_async(self.asyncQueue){data in
            do {
                let res = try super.getBattery()
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: res, error: nil)
                })
            }
            catch let error {
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: 0, error: error)
                })
            }
        }
    }
    
    public func getScore(callback:((result: Int, error: ErrorType?) -> Void )?){
        dispatch_async(self.asyncQueue){data in
            do {
                let res = try super.getScore()
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: res, error: nil)
                })
            }
            catch let error {
                dispatch_async(dispatch_get_main_queue(), {
                    callback?(result: 0, error: error)
                })
            }
        }
    }
}