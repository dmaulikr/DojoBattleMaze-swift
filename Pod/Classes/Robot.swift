//
//  Robot.swift
//  DojoBattleMaze
//
//  Created by Vincenzo Scamporlino on 11/01/16.
//  Copyright © 2016 CoderDojo Stockholm. All rights reserved.
//

import Foundation
import SocketIOClientSwift

public enum RobotDir : Int{
    case Up    = -1
    case Right = 10
    case Down  = 1
    case Left  = -10
}

public enum RobotItem : Int{
    case Player  = 100
    case Wall    = 1
    case Empty   = 0
    case ExtWall = -1
}

public enum RobotState : Int{
    case NoGame         = 1
    case WaitForPlayers = 2
    case Playing        = 3
    case Finished       = 4
}

public enum RobotError : ErrorType{
    case Fired
    case GameOver
    case NotEnoughBattery
}

public protocol RobotEventListenerProtocol{
    func onMessage(message : String);
}

public class Robot {
    var socket: SocketIOClient;
    var playerName = "";
    var state = RobotState.NoGame;
    var socketQueue = dispatch_queue_create("com.dojo.SocketQueue", DISPATCH_QUEUE_CONCURRENT);
    var gameQueue = dispatch_queue_create("com.dojo.GameQueue", DISPATCH_QUEUE_SERIAL);
    var flagIsFired = false;
    var gameOver = false;
    var listener : RobotEventListenerProtocol?

    public init(endpoint : String, namespace: String){
        socket = SocketIOClient(socketURL: NSURL(string: endpoint)!, options: [.Log(true), .ForceWebsockets(true),
            .ForceNew(true), .Nsp(namespace), .HandleQueue(socketQueue)]);
    }
    
    private func listenToEvents(){
        socket.on("connect"){data in
            self.emitMessage("Connected");
        }
        socket.on("game-accept-registrations"){[weak self] data in
            self?.state = RobotState.WaitForPlayers;
            self?.emitMessage("ServerIsAcceptingRegistrations");
            self?.register();
            self?.emitMessage("Registered");
        }
        socket.on("game-started"){[weak self] data in
            self?.emitMessage("GameStarted");
            self?.state = RobotState.Playing;
            self?.flagIsFired = false;
            self?.gameOver = false;
            self?.startLogic();
        }
        socket.on("player-fired"){[weak self] data, ack in
            let gameOver = data[0] as? Bool;
            self?.flagIsFired = true;
            self?.gameOver = gameOver!;
            self?.emitMessage(gameOver == true ? "GameEnded" : "PlayerFired");
        }
        socket.on("game-ended"){[weak self] data in
            self?.state = RobotState.Finished;
            self?.gameOver = true;
            self?.emitMessage("GameEnded");
        }
        socket.on("disconnect"){[weak self] data in
            self?.emitMessage("Disconnect");
        }
    }
    
    private func startLogic(){
        dispatch_async(self.gameQueue) { () -> Void in
            self.play();
        }
    }
    
    private func sendMessage(message : String) throws -> AnyObject?{
        return try self.sendMessage(message, obj: nil);
    }
    
    private func sendMessage(message : String, obj : AnyObject!) throws -> AnyObject?{
        if(self.gameOver){
            throw RobotError.GameOver;
        }
        if(self.flagIsFired){
            self.startLogic();
            self.flagIsFired = false;
            throw RobotError.Fired;
        }
        let sem = dispatch_semaphore_create(0);
        var ret : AnyObject? = nil;
        let param = obj == nil ? "" : obj;
        self.socket.emitWithAck(message, param)(timeoutAfter: 0){(data : Array<AnyObject>) in
            dispatch_async(self.socketQueue){
                ret = data[0];
                dispatch_semaphore_signal(sem);
            }
        }
        dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
        
        return ret;
    }
    
    private func register(){
        if let obj = try! self.sendMessage("register", obj: self.playerName){
            let name = obj as! String;
            self.playerName = name;
        }
    }
    
    public func initialize(playerName : String){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0)) { () -> Void in
            self.playerName = playerName;
            self.listenToEvents();
            self.socket.connect();
            if(self.state == RobotState.WaitForPlayers){
                self.register();
                self.emitMessage("Registered");
            }
        }
    }
    
    public func play(){
        //TODO
    }
    
    public func move(dir : RobotDir) throws -> Bool{
        let response = try self.sendMessage("move", obj: dir.rawValue) as! Dictionary<String, AnyObject>;
        let ack = response["ack"] as! NSNumber;
        if(!ack.boolValue){
            throw RobotError.NotEnoughBattery;
        }
        let res = response["data"] as! NSNumber;
        return res.boolValue;
    }
    
    public func look(dir: RobotDir) throws -> (item: RobotItem, distance: Int){
        let response = try self.sendMessage("look", obj: dir.rawValue) as! Dictionary<String, AnyObject>;
        let item = (response["item"]) as! NSNumber;
        let distance = (response["distance"]) as! NSNumber;
        return (item: RobotItem(rawValue: item.longValue)!, distance: distance.longValue);
    }
    
    public func fire(dir: RobotDir) throws -> Bool{
        let response = try self.sendMessage("fire", obj: dir.rawValue) as! Dictionary<String, AnyObject>;
        if(!(response["ack"] as! Bool)){
            throw RobotError.NotEnoughBattery;
        }
        return response["data"] as! Bool;
    }
    
    public func getPosition() throws -> (x:Int, y:Int){
        let response = try self.sendMessage("position") as! Dictionary<String, AnyObject>;
        return (x: response["x"] as! Int, y: response["y"] as! Int);
    }
    
    public func teleport() throws -> (x:Int, y:Int){
        let response = try self.sendMessage("teleport") as! Dictionary<String, AnyObject>;
        if(!(response["ack"] as! Bool)){
            throw RobotError.NotEnoughBattery;
        }
        let position = response["data"];
        return (x: position!["x"] as! Int, y: position!["y"] as! Int);
    }
    
    public func setEventListener(listener: RobotEventListenerProtocol){
        self.listener = listener;
    }
    
    private func emitMessage(message : String){
        if let listener = self.listener{
            listener.onMessage(message);
        }
    }

    public func getBattery() throws -> Int{
        let battery = try self.sendMessage("battery") as! NSNumber;
        return battery.longValue;
    }
    
    public func getScore() throws -> Int{
        let score = try self.sendMessage("score") as! NSNumber;
        return score.longValue;
    }
    
}