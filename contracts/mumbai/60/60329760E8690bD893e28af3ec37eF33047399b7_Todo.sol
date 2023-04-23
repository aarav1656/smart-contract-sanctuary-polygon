/**
 *Submitted for verification at polygonscan.com on 2023-04-22
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title ETHTaipei sample app
contract Todo {
    // a struct of Task
    struct Task {
        string name;
        bool completed;
    }

    event Create(address indexed creator, string indexed name);


    // map of owner to tasks
    mapping(address => Task[]) listOf;

    /// @dev Create a task and add it to the list
    function createTask(string calldata _name) external {
        // Add a new task to the caller's list
        listOf[msg.sender].push(Task(_name, false));
        emit Create(msg.sender, _name);
    }

    // @dev Update a task's completeness
    function updateTask(uint256 _index) external {
        // Get the task by index as reference
        Task storage task = listOf[msg.sender][_index];
        // toggle 'completed'
        task.completed = !task.completed;
    }

    // @dev Retrieve a task by specified index
    function getTask(uint256 _index) external view returns (string memory name, bool isCompeleted) {
        // Get the list by caller, and get the task by index
        Task memory task = listOf[msg.sender][_index];
        name = task.name;
        isCompeleted = task.completed;
    }

    /// @dev Get the size of the list
    function getListSize() external view returns (uint256) {
        return listOf[msg.sender].length;
    }

    /// @dev Get the list
    function getList() external view returns (Task[] memory) {
        return listOf[msg.sender];
    }

    // @dev Delete a task by specified index
    function deleteTask(uint256 _index) external {
        Task[] storage taskList = listOf[msg.sender];
        uint listSize = taskList.length;
        require(_index < listSize, "invalid index");


        for (uint256 i = _index; i < listSize - 1; i++) {
            taskList[i] = taskList[i + 1];
        }
        taskList.pop();
    }
}