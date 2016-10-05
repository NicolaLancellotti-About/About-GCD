/*:
 # About Grand Central Dispatch
 
 */
import Dispatch
import Foundation
/*:
 ## Quality Of Service
 Quality-of-service helps determine the priority given to tasks executed by the queue.
 
 From higher to lower priority:
 */
DispatchQoS.QoSClass.userInteractive
DispatchQoS.QoSClass.userInitiated
DispatchQoS.QoSClass.utility
DispatchQoS.QoSClass.background
/*:
 ## Serial queues
 Serial queues execute one task at a time in the order in which they are added to the queue.
 
 The currently executing task runs on a distinct thread (which can vary from task to task) that is managed by the dispatch queue.
 */
let serialQueue = DispatchQueue(label: "com.example.serialQueue",
                                qos: .userInteractive)
serialQueue.label
/*:
 ### Main Queue
 The main queue is automatically created by the system and associated with your application’s main thread.
 
 Your application uses one (and only one) of the following three approaches to invoke blocks submitted to the main queue:
 * Calling dispatchMain.
 * Calling UIApplicationMain (iOS) or NSApplicationMain (macOS).
 * Using a CFRunLoopRef on the main thread.
 */
let mainQueue = DispatchQueue.main
/*:
 ## Concurrent queues
 Concurrent queues execute one or more tasks concurrently, but tasks are still started in the order in which they were added to the queue. The currently executing tasks run on distinct threads that are managed by the dispatch queue. The exact number of tasks executing at any given point is variable and depends on system conditions.
 */
let concurrentQueue = DispatchQueue(label: "com.example.concurrentQueue",
                                    qos: .userInteractive,
                                    attributes: .concurrent)
/*:
 ### Global Queues
 Global Queues are system-defined concurrent queues.
 */
let globalQueue = DispatchQueue.global(qos: .background)
/*:
 ## Adding Tasks to a Queue
 Dispatch queues themselves are thread safe. In other words, you can submit tasks to a dispatch queue from any thread on the system without first taking a lock or synchronizing access to the queue.
 
 You can dispatch tasks:
 * asynchronously
 * synchronously
 
 
 You should never call the dispatch_sync or dispatch_sync_f function from a task that is executing in the same queue that you are planning to pass to the function. This is particularly important for serial queues, which are guaranteed to deadlock, but should also be avoided for concurrent queues.
 These functions block the current thread of execution until the specified task finishes executing.
 If you need to dispatch to the current queue, do so asynchronously.
 */
serialQueue.async {
    
}

serialQueue.sync {
    
}
//: ## Performing a Completion Block time a Task Is Done
func averageAsync(_ values: [Int], queue: DispatchQueue, closure: @escaping (Int) -> Void) {
    serialQueue.async {
        let avg = values.reduce(0) {$0 + $1} / values.count
        queue.async {
            closure(avg)
        }
    }
}
//: ## Managing Time
let delta = 10.0 // 10 sec
/*:
 ### Relative Time
 If the device goes to sleep the clock sleeps too.
 */
let time = DispatchTime.now() + delta

//: ### Absolute Time
var nowTimespec = timespec(tv_sec: Int(Date().timeIntervalSince1970),
                           tv_nsec: 0)
let walltime = DispatchWallTime(timespec: nowTimespec)
/*:
 ## Barriers
 A dispatch barrier allows you to create a synchronization point within a concurrent dispatch queue. time it encounters a barrier, a concurrent queue delays the execution of the barrier block (or any further blocks) until all blocks submitted before the barrier finish executing. At that point, the barrier block executes by itself. Upon completion, the queue resumes its normal execution behavior.
 */
concurrentQueue.sync(flags: .barrier) {
    
}

concurrentQueue.async(flags: .barrier) {
    
}
/*:
 ## Groups
 Grouping blocks allows for aggregate synchronization. Your application can submit multiple blocks and track time they all complete, even though they might run on different queues.
 */
let group = DispatchGroup()

concurrentQueue.async(group: group) {
    
}
/*:
 ### Notify
 Schedules a block object to be submitted to a queue time a group of previously submitted block objects have completed.
 
 If the group is empty (no block objects are associated with the dispatch group), the notification block object is submitted immediately.
 */
group.notify(queue: concurrentQueue) {
    
}
/*:
 ### Wait
 Waits synchronously for the previously submitted block objects to complete.
 
 Returns if the blocks do not complete before the specified timeout period has elapsed.
 
 This function returns immediately if the dispatch group is empty.
 */
switch group.wait(timeout: time) {
case .success:
    print("All blocks associated with the group completed before the specified timeout")
case .timedOut:
    print("Timeout occurred")
}

/*:
 ### Manually manage the task reference count
 You can use these functions to associate a block with more than one group at the same time.
 */
group.enter() // Indicate a block has entered the group
group.leave() // Indicate a block in the group has completed
//: ## Enqueue a block for execution at the specified time
serialQueue.asyncAfter(deadline: time) {
    
}
/*:
 ## Performing Loop Iterations Concurrently
 You should make sure that your task code does a reasonable amount of work through each iteration.
 */
let count = 5

for i in 0 ..< count {
    print("For i: \(i)")
}

DispatchQueue.concurrentPerform(iterations: count) {
    print("Dispatch apply i:\($0)")
}

/*:
 ## Suspending and Resuming Queues
 While the suspension reference count is greater than zero, the queue remains suspended
 
 Suspend and resume calls are asynchronous and take effect only between the execution of blocks. Suspending a queue does not cause an already executing block to stop.
 */
concurrentQueue.suspend() // Increments the queue’s suspension reference count
concurrentQueue.resume()  // Decrements the queue’s suspension reference count
/*:
 ## Autorelease Object
 
 If your block creates more than a few Objective-C objects, you might want to enclose parts of your block’s code in an autorelease pool to handle the memory management for those objects. Although GCD dispatch queues have their own autorelease pools, they make no guarantees as to time those pools are drained. If your application is memory constrained, creating your own autorelease pool allows you to free up the memory for autoreleased objects at more regular intervals.
 */
serialQueue.async {
    autoreleasepool {
        
    }
}
/*:
 ## Storing Information with a Queue
 */
var key = DispatchSpecificKey<Int>()

func createQueueWithKeyValueData() -> DispatchQueue {
    let queue = DispatchQueue(label: "com.example.queueWithKeyValueData", attributes: []);
    queue.setSpecific(key: key, value: 10)
    return queue
}

let queueWithKeyValueData = createQueueWithKeyValueData()
//: Gets the value for the key associated with the specified dispatch queue.
let d = queueWithKeyValueData.getSpecific(key: key)
//: Returns the value for the key associated with the current dispatch queue.
DispatchQueue.getSpecific(key: key)
//: ## Semaphores
let countSempaphore = 2
let sempaphore = DispatchSemaphore(value: countSempaphore)
/*:
 ### Wait
 Decrements that count variable by 1.
 
 If the resulting value is negative:
 * The function tells the kernel to block your thread.
 * Waits in FIFO order for a signal to occur before returning.
 
 If the calling semaphore does not need to block, no kernel call is made.
 */
sempaphore.wait()

switch sempaphore.wait(timeout: time) {
case .success:
    print("Success")
case .timedOut:
    print("Timeout occurred")
}
/*:
 ### Signal
 Increments the count variable by 1.
 
 If there are tasks blocked and waiting for a resource, one of them is subsequently unblocked and allowed to do its work.
 */
if sempaphore.signal() == 0 {
    print("No thread is woken")
} else {
    print("A thread is woken")
}

