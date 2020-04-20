### 二叉树节点定义

```go
type TreeNode struct {
	Val   int
	Left  *TreeNode
	Right *TreeNode
}
```

### 栈定义
```go
type Stack struct {
	stack *list.List
}

func NewStack() Stack{
	return Stack{stack:list.New()}
}

func (stack Stack) Push(element interface{}){
	stack.stack.PushBack(element)
}

func (stack Stack) Pop() interface{}{
	e := stack.stack.Back()
	if e == nil {
		return nil
	}
	stack.stack.Remove(e)
	return e
}

func (stack Stack) Len() int {
	return stack.stack.Len()
}

func (stack Stack) Empty() bool{
	if stack.stack.Len() > 0 {
		return false
	}
	return true
}
```