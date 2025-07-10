#!/bin/bash
# update_progress.sh
# Script to help agents update their progress in the master checklist

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
CHECKLIST_FILE="MASTER_PROGRESS_CHECKLIST.md"
BACKUP_FILE="MASTER_PROGRESS_CHECKLIST.backup.md"

echo -e "${BLUE}HealthAI 2030 - Progress Update Tool${NC}"
echo "=========================================="

# Function to backup current checklist
backup_checklist() {
    echo -e "${YELLOW}Creating backup of current checklist...${NC}"
    cp "$CHECKLIST_FILE" "$BACKUP_FILE"
    echo -e "${GREEN}Backup created: $BACKUP_FILE${NC}"
}

# Function to show current progress
show_progress() {
    echo -e "${BLUE}Current Progress Summary:${NC}"
    echo "=========================="
    
    # Count completed tasks
    total_tasks=$(grep -c "\[ \]" "$CHECKLIST_FILE" || echo "0")
    completed_tasks=$(grep -c "\[x\]" "$CHECKLIST_FILE" || echo "0")
    
    if [ "$total_tasks" -gt 0 ]; then
        progress_percent=$((completed_tasks * 100 / total_tasks))
        echo -e "${GREEN}Total Tasks: $total_tasks${NC}"
        echo -e "${GREEN}Completed Tasks: $completed_tasks${NC}"
        echo -e "${GREEN}Progress: $progress_percent%${NC}"
    else
        echo -e "${YELLOW}No tasks found in checklist${NC}"
    fi
    
    echo ""
}

# Function to update task status
update_task() {
    local agent_number=$1
    local task_description=$2
    local new_status=$3
    
    echo -e "${BLUE}Updating task for Agent $agent_number...${NC}"
    
    # Create timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    # Update the task in the checklist
    if [ "$new_status" = "completed" ]; then
        # Mark as completed
        sed -i "s/- \[ \] \*\*$task_description\*\*/- [x] **$task_description** ✅ Completed: $timestamp/" "$CHECKLIST_FILE"
        echo -e "${GREEN}Task marked as completed: $task_description${NC}"
    elif [ "$new_status" = "in_progress" ]; then
        # Mark as in progress
        sed -i "s/- \[ \] \*\*$task_description\*\*/- [ ] **$task_description** 🔄 In Progress: $timestamp/" "$CHECKLIST_FILE"
        echo -e "${YELLOW}Task marked as in progress: $task_description${NC}"
    elif [ "$new_status" = "blocked" ]; then
        # Mark as blocked
        sed -i "s/- \[ \] \*\*$task_description\*\*/- [ ] **$task_description** 🚫 Blocked: $timestamp/" "$CHECKLIST_FILE"
        echo -e "${RED}Task marked as blocked: $task_description${NC}"
    fi
}

# Function to add new task
add_task() {
    local agent_number=$1
    local task_description=$2
    local due_date=$3
    
    echo -e "${BLUE}Adding new task for Agent $agent_number...${NC}"
    
    # Add task to appropriate section
    # This is a simplified version - in practice, you'd need more sophisticated parsing
    echo "- [ ] **$task_description**" >> "$CHECKLIST_FILE"
    echo -e "${GREEN}New task added: $task_description${NC}"
}

# Function to show agent tasks
show_agent_tasks() {
    local agent_number=$1
    
    echo -e "${BLUE}Tasks for Agent $agent_number:${NC}"
    echo "========================"
    
    # Extract agent tasks (simplified)
    grep -A 5 -B 5 "Agent $agent_number" "$CHECKLIST_FILE" || echo "No tasks found for Agent $agent_number"
}

# Function to update progress percentage
update_progress_percentage() {
    echo -e "${BLUE}Updating progress percentage...${NC}"
    
    # Count tasks and calculate percentage
    total_tasks=$(grep -c "\[ \]" "$CHECKLIST_FILE" || echo "0")
    completed_tasks=$(grep -c "\[x\]" "$CHECKLIST_FILE" || echo "0")
    
    if [ "$total_tasks" -gt 0 ]; then
        progress_percent=$((completed_tasks * 100 / total_tasks))
        
        # Update the progress percentage in the file
        sed -i "s/Overall Progress: [0-9]*%/Overall Progress: $progress_percent%/" "$CHECKLIST_FILE"
        sed -i "s/Overall Progress: [0-9]*% ([0-9]*\/[0-9]* tasks completed)/Overall Progress: $progress_percent% ($completed_tasks\/$total_tasks tasks completed)/" "$CHECKLIST_FILE"
        
        echo -e "${GREEN}Progress updated to $progress_percent% ($completed_tasks/$total_tasks tasks)${NC}"
    fi
}

# Main menu
show_menu() {
    echo ""
    echo -e "${BLUE}Available Actions:${NC}"
    echo "1. Show current progress"
    echo "2. Update task status"
    echo "3. Add new task"
    echo "4. Show agent tasks"
    echo "5. Update progress percentage"
    echo "6. Create backup"
    echo "7. Exit"
    echo ""
    read -p "Select an action (1-7): " choice
}

# Main execution
main() {
    # Check if checklist file exists
    if [ ! -f "$CHECKLIST_FILE" ]; then
        echo -e "${RED}Error: $CHECKLIST_FILE not found${NC}"
        exit 1
    fi
    
    while true; do
        show_menu
        
        case $choice in
            1)
                show_progress
                ;;
            2)
                read -p "Enter agent number (1-5): " agent_num
                read -p "Enter task description: " task_desc
                echo "Status options: completed, in_progress, blocked"
                read -p "Enter new status: " status
                update_task "$agent_num" "$task_desc" "$status"
                ;;
            3)
                read -p "Enter agent number (1-5): " agent_num
                read -p "Enter task description: " task_desc
                read -p "Enter due date (YYYY-MM-DD): " due_date
                add_task "$agent_num" "$task_desc" "$due_date"
                ;;
            4)
                read -p "Enter agent number (1-5): " agent_num
                show_agent_tasks "$agent_num"
                ;;
            5)
                update_progress_percentage
                ;;
            6)
                backup_checklist
                ;;
            7)
                echo -e "${GREEN}Exiting...${NC}"
                exit 0
                ;;
            *)
                echo -e "${RED}Invalid choice. Please select 1-7.${NC}"
                ;;
        esac
    done
}

# Run main function
main "$@" 