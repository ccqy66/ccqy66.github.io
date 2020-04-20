
### 前序遍历：

#### 递归写法
```go
func PreTraversal(node *TreeNode) {
	if node == nil {
		return
	}
	fmt.Print(node.Val)
	PreTraversal(node.Left)
	PreTraversal(node.Right)
}
```

#### 非递归写法
```go
func PreTraversalNoRecursion(node *TreeNode) {
	if node == nil {
		return
	}
	stack := NewStack()
	result := make([]int, 0)
	stack.Push(node)
	for !stack.Empty() {
		e := stack.Pop()
		v := e.(*TreeNode)
		result = append(result, v.Val)
		if v.Right != nil{
			stack.Push(v.Right)
		}
		if v.Left != nil{
			stack.Push(v.Left)
		}
	}
	fmt.Println(result)
}

```
### 中序遍历：
```go
func MiddleTraversal(node *TreeNode) {
	if node == nil {
		return
	}
	MiddleTraversal(node.Left)
	fmt.Print(node.Val)
	MiddleTraversal(node.Right)
}
```

### 后序遍历
```go
func AfterTraversal(node *TreeNode) {
	if node == nil {
		return
	}
	AfterTraversal(node.Left)
	AfterTraversal(node.Right)
	fmt.Print(node.Val)
}
```