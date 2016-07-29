/*:
 # About Grand Central Dispatch
 
 */
import Dispatch
/*:
 ## Quality Of Service
 Quality-of-service helps determine the priority given to tasks executed by the queue.
 
 From higher to lower priority:
 */
QOS_CLASS_USER_INTERACTIVE
QOS_CLASS_USER_INITIATED
QOS_CLASS_UTILITY
QOS_CLASS_BACKGROUND
/*:
 ## Serial queues
 Serial queues execute one task at a time in the order in which they are added to the queue.
 
 The currently executing task runs on a distinct thread (which can vary from task to task) that is managed by the dispatch queue.
 */
let serialQueueAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0)
let serialQueue = dispatch_queue_create("com.example.serialQueue", serialQueueAttr)

String.fromCString(dispatch_queue_get_label(serialQueue))!
/*:
 ### Main Queue
 The main queue is automatically created by the system and associated with your application’s main thread.
 
 Your application uses one (and only one) of the following three approaches to invoke blocks submitted to the main queue:
 * Calling dispatch_main.
 * Calling UIApplicationMain (iOS) or NSApplicationMain (macOS).
 * Using a CFRunLoopRef on the main thread.
 */
let mainQueue = dispatch_get_main_queue()
/*:
 ## Concurrent queues
 Concurrent queues execute one or more tasks concurrently, but tasks are still started in the order in which they were added to the queue. The currently executing tasks run on distinct threads that are managed by the dispatch queue. The exact number of tasks executing at any given point is variable and depends on system conditions.
 */
let concurrentQueueAttr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_CONCURRENT, QOS_CLASS_USER_INTERACTIVE, 0)
let concurrentQueue = dispatch_queue_create("com.example.concurrentQueue", concurrentQueueAttr)
/*:
 ### Global Queues
 Global Queues are system-defined concurrent queues.
 */
let globalQueue = dispatch_get_global_queue(QOS_CLASS_BACKGROUND, 0)
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
dispatch_async(serialQueue) {

}

dispatch_sync(serialQueue) {
    
}
//: ## Performing a Completion Block When a Task Is Done
func averageAsync(values: [Int], queue: dispatch_queue_t, block: (Int) -> Void) {
    dispatch_async(serialQueue) {
        let avg = values.reduce(0) {$0 + $1} / values.count
        dispatch_async(queue) {
            block(avg)
        }
    }
}
/*:
 ## Barriers
 A dispatch barrier allows you to create a synchronization point within a concurrent dispatch queue. When it encounters a barrier, a concurrent queue delays the execution of the barrier block (or any further blocks) until all blocks submitted before the barrier finish executing. At that point, the barrier block executes by itself. Upon completion, the queue resumes its normal execution behavior.
 */
dispatch_barrier_sync(concurrentQueue) {
    
}

dispatch_barrier_async(concurrentQueue) {
    
}
/*:
 ## Groups
 Grouping blocks allows for aggregate synchronization. Your application can submit multiple blocks and track when they all complete, even though they might run on different queues.
 */
let group: dispatch_group_t = dispatch_group_create();

dispatch_group_async(group, concurrentQueue) {

}
/*:
 ### Notify
 Schedules a block object to be submitted to a queue when a group of previously submitted block objects have completed.
 
 If the group is empty (no block objects are associated with the dispatch group), the notification block object is submitted immediately.
 */
dispatch_group_notify(group, concurrentQueue) {
    
}
/*:
 ### Wait
 Waits synchronously for the previously submitted block objects to complete.
 
 Returns if the blocks do not complete before the specified timeout period has elapsed.
 
 This function returns immediately if the dispatch group is empty.
 */
let delta = Int64(10 * Double(NSEC_PER_SEC)) // 10 sec
let when = dispatch_time(DISPATCH_TIME_NOW, delta)

if dispatch_group_wait(group, when) == 0 {
    print("All blocks associated with the group completed before the specified timeout")
} else {
    print("Timeout occurred")
}
/*:
 ### Manually manage the task reference count
 You can use these functions to associate a block with more than one group at the same time.
 */
dispatch_group_enter(group) // Indicate a block has entered the group
dispatch_group_leave(group) // Indicate a block in the group has completed
//: ## Enqueue a block for execution at the specified time
dispatch_after(when, mainQueue) {
    
}
/*:
 ## Performing Loop Iterations Concurrently
 You should make sure that your task code does a reasonable amount of work through each iteration.
 */
let count = 5

for i in 0 ..< count {
    print("For i: \(i)")
}

dispatch_apply(count, concurrentQueue) {
    print("Dispatch apply i:\($0)")
}
/*:
 ## Executes a block object once and only once for the lifetime of an application
 
 If called simultaneously from multiple threads, this function waits synchronously until the block has completed.
 
 The predicate must point to a variable stored in global or static scope. The result of using a predicate with automatic or dynamic storage (including Objective-C instance variables) is undefined.
 */
var token: dispatch_once_t = 0
dispatch_once(&token) {
    
}
/*:
 ## Suspending and Resuming Queues
 While the suspension reference count is greater than zero, the queue remains suspended
 
 Suspend and resume calls are asynchronous and take effect only between the execution of blocks. Suspending a queue does not cause an already executing block to stop.
 */
dispatch_suspend(concurrentQueue) // Increments the queue’s suspension reference count
dispatch_resume(concurrentQueue)  // Decrements the queue’s suspension reference count
/*:
 ## Autorelease Object
 
 If your block creates more than a few Objective-C objects, you might want to enclose parts of your block’s code in an autorelease pool to handle the memory management for those objects. Although GCD dispatch queues have their own autorelease pools, they make no guarantees as to when those pools are drained. If your application is memory constrained, creating your own autorelease pool allows you to free up the memory for autoreleased objects at more regular intervals.
 */
dispatch_async(serialQueue) {
    autoreleasepool {
        
    }
}
/*:
 ## Storing Information with a Queue
 */
class MyDataContext {
    
}

var data: UnsafeMutablePointer<Void>
//: #### Key/Value Data
var key = 0

func createQueueWithKeyValueData() -> dispatch_queue_t! {
    let data = UnsafeMutablePointer<MyDataContext>.alloc(1)
    data.initialize(MyDataContext())
    
    let queue = dispatch_queue_create("com.example.queueWithKeyValueData", nil);
    guard queue != nil else { return nil }
    
    // If context is nil, the destructor function is ignored.
    dispatch_queue_set_specific(queue, &key, data) {
        let data = UnsafeMutablePointer<MyDataContext>($0)
        data.destroy()
        data.dealloc(1)
    }
    
    return queue
}

let queueWithKeyValueData = createQueueWithKeyValueData()
//: Gets the value for the key associated with the specified dispatch queue.
data = dispatch_queue_get_specific(queueWithKeyValueData, &key)
//: Returns the value for the key associated with the current dispatch queue.
data = dispatch_get_specific(&key)
//: #### Context
func createQueueWithContext() -> dispatch_queue_t! {
    let data = UnsafeMutablePointer<MyDataContext>.alloc(1)
    data.initialize(MyDataContext())
    
    let queue = dispatch_queue_create("com.example.queueWithContext", nil);
    guard queue != nil else { return nil }
    
    dispatch_set_context(queue, data)
    
    //  The finalizer is not called if the application-defined context is NULL.
    dispatch_set_finalizer_f(queue) {
        let data = UnsafeMutablePointer<MyDataContext>($0)
        data.destroy()
        data.dealloc(1)
    }
    return queue
}

let queueWithContext = createQueueWithContext()
data = dispatch_get_context(queueWithContext)
//: ## Semaphores
let countSempaphore = 10
let sempaphore: dispatch_semaphore_t = dispatch_semaphore_create(countSempaphore)
/*:
 ### Wait
 Decrements that count variable by 1.
 
 If the resulting value is negative:
 * The function tells the kernel to block your thread.
 * Waits in FIFO order for a signal to occur before returning.
 
 If the calling semaphore does not need to block, no kernel call is made.
 */
if dispatch_semaphore_wait(sempaphore, DISPATCH_TIME_FOREVER) == 0 {
    print("Success")
} else {
    print("Timeout occurred")
}
/*:
 ### Signal
 Increments the count variable by 1.
 
 If there are tasks blocked and waiting for a resource, one of them is subsequently unblocked and allowed to do its work.
 */
if dispatch_semaphore_signal(sempaphore) == 0 {
    print("No thread is woken")
} else {
    print("A thread is woken")
}
