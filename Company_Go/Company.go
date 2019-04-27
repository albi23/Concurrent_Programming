package main

import (
	config "./configuration"
	"fmt"
	"math/rand"
	"os"
	"strconv"
	"time"
)

type task struct {
	firstArg  int
	secondArg int
	operation string
}

type writeTask struct {
	task task
	resp chan bool
}

type readTask struct {
	request bool
	resp    chan task
}

type writeWarehouse struct {
	result   chan bool
	doneTask string
}

type readWarehouse struct {
	request  bool
	response chan string
}

var listOfTasks = make([]task, 0)
var writeTaskChan = make(chan *writeTask)
var readTaskChan = make(chan *readTask)
var warehouseList = make([]string, 0)
var writeWarehouseChan = make(chan *writeWarehouse)
var readWarehouseChan = make(chan *readWarehouse)
var deceptive = false

func bossTask() {
	var operations = []string{"+", "-", "*"}
	for {
		s1 := rand.NewSource(time.Now().UnixNano())
		r1 := rand.New(s1)
		firstArg := r1.Intn(10000)
		secondArg := r1.Intn(10000)
		operation := operations[r1.Intn(3)]
		toDoTask := &writeTask{
			task: task{firstArg, secondArg, operation},
			resp: make(chan bool)}
		writeTaskChan <- toDoTask
		response := <-toDoTask.resp
		if deceptive && response {
			fmt.Println("Boss add new task: ", firstArg, operation, secondArg)
		}
		time.Sleep(time.Duration(config.TimeForNewTask) * time.Second)

	}
}

func worker(idWorker int) {

	for {
		takenTask := &readTask{request: true, resp: make(chan task)}
		readTaskChan <- takenTask
		task := <-takenTask.resp
		if deceptive && task.firstArg != 0 {
			fmt.Println("[Worker ", idWorker, "] Operation to do : ", task.firstArg, task.operation, task.secondArg)
		}
		switch task.operation {

		case "+":
			{
				newElement := &writeWarehouse{result: make(chan bool), doneTask: strconv.Itoa(task.firstArg + task.secondArg)}
				writeWarehouseChan <- newElement
				<-newElement.result
				time.Sleep(time.Duration(config.TimeReciveTaskForWorker) * time.Second)
			}
		case "-":
			{
				newElement := &writeWarehouse{result: make(chan bool), doneTask: strconv.Itoa(task.firstArg - task.secondArg)}
				writeWarehouseChan <- newElement
				<-newElement.result
				time.Sleep(time.Duration(config.TimeReciveTaskForWorker) * time.Second)
			}

		case "*":
			{
				newElement := &writeWarehouse{result: make(chan bool), doneTask: strconv.Itoa(task.firstArg * task.secondArg)}
				writeWarehouseChan <- newElement
				<-newElement.result
				time.Sleep(time.Duration(config.TimeReciveTaskForWorker) * time.Second)
			}

		}
	}
}

func client() {

	for {
		productToBuy := &readWarehouse{request: true, response: make(chan string)}
		readWarehouseChan <- productToBuy
		if deceptive {
			fmt.Println("Client bought product: ", <-productToBuy.response)
		} else {
			<-productToBuy.response
		}
		time.Sleep(time.Duration(config.TimeForBuy) * time.Second)

	}
}

func checkStatusOfWarehouse() {
	fmt.Println("writeWarehouse: ", warehouseList)
}

func checkTaskToDo() {
	fmt.Println("Tasks to do: ", listOfTasks)
}

func taskController() {

	for {
		select {

		case newtask := <-taskAddGuard(len(listOfTasks) < config.TaskSize, writeTaskChan):
			listOfTasks = append(listOfTasks, newtask.task)
			newtask.resp <- true

		case takenTask := <-taskGetGuard(len(listOfTasks) >= 1, readTaskChan):
			takenTask.resp <- listOfTasks[0]
			listOfTasks = listOfTasks[1:]
		}

	}
}

func warehouseController() {

	for {
		select {
		case newElement := <-warehouseAddGuard(len(warehouseList) < config.WarehouseSize, writeWarehouseChan):
			warehouseList = append(warehouseList, newElement.doneTask)
			newElement.result <- true

		case takeElement := <-warehouseGetGuard(len(warehouseList) >= 1, readWarehouseChan):
			takeElement.response <- warehouseList[0]
			warehouseList = warehouseList[1:]
		}
	}
}

func warehouseAddGuard(b bool, c chan *writeWarehouse) chan *writeWarehouse {
	if !b {
		return nil
	}
	return c
}
func warehouseGetGuard(b bool, c chan *readWarehouse) chan *readWarehouse {
	if !b {
		return nil
	}
	return c
}

func taskAddGuard(b bool, c chan *writeTask) chan *writeTask {

	if !b {
		return nil
	}
	return c
}

func taskGetGuard(b bool, c chan *readTask) chan *readTask {

	if !b {
		return nil
	}
	return c
}

func main() {

	fmt.Println("Choose: deceptive mode/quiet mode  D/Q: ")

	var chosedMode string
	fmt.Scanln(&chosedMode)

	go taskController()
	go warehouseController()
	go bossTask()
	for i := 0; i < config.NumberOfWorkers; i++ {
		go worker(i + 1)
	}
	go client()

	if chosedMode == "D" {
		deceptive = true
	} else if chosedMode == "Q" {

		for {
			fmt.Println("Choose ")
			fmt.Println("      1: to check warehouse ")
			fmt.Println("      2: to check task to do  ")
			fmt.Println("      3: to quit   ")

			fmt.Scanln(&chosedMode)
			if chosedMode == "1" {
				checkStatusOfWarehouse()
			}
			if chosedMode == "2" {
				checkTaskToDo()
			}
			if chosedMode == "3" {
				os.Exit(0)
			}
		}

	}

	fmt.Scanln()

}
