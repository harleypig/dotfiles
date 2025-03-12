# jq Tutorial: JSON Processing Made Easy

## What is jq and Why Use It?

`jq` is a lightweight and flexible command-line JSON processor. Think of it as
"sed for JSON data" - it lets you slice, filter, map, and transform structured
data with the same ease that sed, awk, and grep let you play with text.

### Common Use Cases:

- **API Response Processing**: Extract specific fields from REST API responses
- **Configuration Management**: Parse and modify JSON configuration files
- **Data Analysis**: Filter and transform JSON datasets
- **DevOps Automation**: Process JSON outputs from cloud services (AWS, Azure, GCP)
- **Debugging**: Pretty-print JSON for better readability

### Example:

```bash
# Pretty-print JSON
curl "https://api.example.com/data" | jq '.'

# Extract specific fields
curl "https://api.example.com/users" | jq '.users[] | {name: .name, email: .email}'
```

## jq Basics: Understanding the Paradigm

jq operates on a few key principles that make it powerful yet approachable:

### Data-Centric

jq is designed specifically for JSON data structures. It understands:

- Objects (key-value pairs)
- Arrays (ordered collections)
- Basic values (strings, numbers, booleans, null)

### Functional

jq follows functional programming concepts:

- **Filters as Functions**: Every jq expression is a "filter" that takes an input and produces an output
- **Composition**: Filters can be chained together with the pipe operator (`|`)
- **Immutability**: Input data is never modified; transformations create new data

### Declarative

With jq, you describe what you want, not how to get it:

- Focus on the data transformation, not the implementation details
- Concise syntax for common operations
- Built-in functions for sorting, grouping, and mathematical operations

### Basic Syntax Examples:

```bash
# Select a field from an object
echo '{"name": "John", "age": 30}' | jq '.name'
# Output: "John"

# Select elements from an array
echo '[1, 2, 3, 4]' | jq '.[]'
# Output:
# 1
# 2
# 3
# 4

# Combine operations
echo '{"users": [{"name": "Alice", "role": "admin"}, {"name": "Bob", "role": "user"}]}' | jq '.users[] | select(.role == "admin") | .name'
# Output: "Alice"
```

## Everything is a Filter: The jq Philosophy

In jq, everything you write is a filter that transforms JSON data. This concept is fundamental to mastering jq.

### Types of Filters:

#### 1. Extraction Filters

These filters pull out specific pieces of data:

```bash
# Identity filter (.) - passes input unchanged
echo '{"a": 1}' | jq '.'
# Output:
# {
#   "a": 1
# }

# Object Identifier (.field)
echo '{"name": "John", "age": 30}' | jq '.age'
# Output: 30

# Array Index
echo '[10, 20, 30]' | jq '.[1]'
# Output: 20

# Array/Object Value Iterator (.[] or .[])
echo '{"a": 1, "b": 2}' | jq '.[]'
# Output:
# 1
# 2
```

#### 2. Construction Filters

These filters create new JSON structures:

```bash
# Create an object
echo '{"first": "John", "last": "Doe"}' | jq '{name: (.first + " " + .last)}'
# Output: {"name": "John Doe"}

# Create an array
echo '{"a": 1, "b": 2}' | jq '[.a, .b, .a + .b]'
# Output: [1, 2, 3]
```

#### 3. Iteration Filters

These filters process collections of data:

```bash
# map - Apply a filter to each element
echo '[1, 2, 3]' | jq 'map(. * 2)'
# Output: [2, 4, 6]

# select - Keep elements that match a condition
echo '[1, 2, 3, 4]' | jq 'map(select(. % 2 == 0))'
# Output: [2, 4]
```

### Combining Filters

The real power of jq comes from combining filters with the pipe operator
(`|`). Let's break down a complex example to see how data flows through each
step:

```bash
# Complex transformation
echo '{"orders": [
  {"id": 1, "items": [{"product": "A", "price": 10}, {"product": "B", "price": 20}]},
  {"id": 2, "items": [{"product": "C", "price": 30}]}
]}' | jq '.orders[] | {order_id: .id, total: (.items | map(.price) | add)}'

# Output:
# {"order_id": 1, "total": 30}
# {"order_id": 2, "total": 30}
```

Let's analyze how this filter works step by step:

1. `.orders[]`
   - Takes the input JSON and selects the "orders" array
   - The `[]` iterates through each element in the array
   - Outputs each order object individually to the next filter

2. `{order_id: .id, total: (...)}`
   - For each order object, constructs a new object with two fields:
     - "order_id": copied from the input object's "id" field
     - "total": calculated by the sub-expression in parentheses

3. Inside the parentheses: `.items | map(.price) | add`
   - `.items`: Selects the "items" array from the current order
   - `map(.price)`: Transforms the array of item objects into an array of just prices
   - `add`: Sums all values in the resulting array

The data transformation at each step:
- Input → `{"orders": [{"id": 1, ...}, {"id": 2, ...}]}`
- After `.orders[]` → `{"id": 1, ...}` then `{"id": 2, ...}` (processed separately)
- After the full filter → `{"order_id": 1, "total": 30}` then `{"order_id": 2, "total": 30}`

This pipeline approach allows you to build complex transformations by
combining simple, focused filters.

### Advanced Filter Techniques

- **Alternative operator (`//`)**: Provide a default value
  ```bash
  echo '{"a": 1}' | jq '.b // "Not found"'
  # Output: "Not found"
  ```

- **Pipe operator (`|`)**: Chain filters together
  ```bash
  echo '{"a": {"b": [1, 2, 3]}}' | jq '.a | .b | .[0]'
  # Output: 1
  ```

- **Comma operator (`,`)**: Run multiple filters on the same input
  ```bash
  echo '{"a": 1, "b": 2}' | jq '.a, .b'
  # Output:
  # 1
  # 2
  ```

Remember that jq's filter-based approach makes complex JSON transformations
both readable and maintainable, which is especially valuable in automation
scripts and data processing pipelines.

## Saving jq Programs in Files

For complex or frequently used jq operations, you can save your jq programs in
files rather than typing them on the command line each time.

### Creating a jq Program File

Create a text file with your jq program:

```bash
# File: calculate-totals.jq
.orders[] | {
  order_id: .id,
  customer: .customer_name,
  total: (.items | map(.price) | add),
  item_count: (.items | length)
}
```

### Running jq with Program Files

There are two main ways to use jq program files:

#### 1. Using the `-f` flag (file)

```bash
# Process orders.json using the program in calculate-totals.jq
jq -f calculate-totals.jq orders.json

# You can still pipe input
cat orders.json | jq -f calculate-totals.jq
```

#### 2. Using the `@` syntax for inline file references

```bash
jq "@calculate-totals.jq" orders.json
```

### Passing Arguments to jq Programs

You can make your jq programs more flexible by using variables:

```bash
# File: filter-by-status.jq
.orders[] | select(.status == $STATUS)
```

Then pass values when invoking jq:

```bash
# Set the STATUS variable to "shipped"
jq --arg STATUS "shipped" -f filter-by-status.jq orders.json
```

### Combining Program Files with Command-Line Filters

You can further process the output of a jq program file:

```bash
# Use the program file and then process its output
jq -f calculate-totals.jq orders.json | jq 'select(.total > 100)'
```

### Including Other jq Files

For larger projects, you can split your jq code into modules and include them:

```bash
# File: common-functions.jq
def total_price: map(.price) | add;
def with_tax($rate): . * (1 + $rate);

# File: process-orders.jq
include "common-functions";
.orders[] | {
  id: .id,
  subtotal: (.items | total_price),
  total: (.items | total_price | with_tax(0.07))
}
```

Run with:
```bash
jq -L . -f process-orders.jq orders.json
```

The `-L .` flag adds the current directory to the search path for includes.

Saving jq programs in files makes them reusable, easier to maintain, and
allows you to build more complex data processing pipelines while keeping your
code organized.

## Resources

### Official Resources

- [jq Homepage](https://stedolan.github.io/jq/) - The official website for jq
- [jq Manual](https://stedolan.github.io/jq/manual/) - Comprehensive documentation
- [jq GitHub Repository](https://github.com/stedolan/jq) - Source code and issue tracking
- [jq Play](https://jqplay.org/) - Interactive jq playground to test expressions online

### Tutorials and Guides

- [jq Cookbook](https://github.com/stedolan/jq/wiki/Cookbook) - Collection of practical recipes
- [Learn jq in Y Minutes](https://learnxinyminutes.com/docs/jq/) - Quick syntax overview
- [Parsing JSON with jq](https://programminghistorian.org/en/lessons/json-and-jq) - Detailed tutorial from Programming Historian

### Community Resources

- [Stack Overflow jq Tag](https://stackoverflow.com/questions/tagged/jq) - Q&A for specific jq problems
- [jq Subreddit](https://www.reddit.com/r/jq/) - Community discussions and examples
- [jq Wiki](https://github.com/stedolan/jq/wiki) - Community-maintained documentation

### Books and In-depth Learning

- [jq Primer: Munging JSON Data](https://earthly.dev/blog/jq-select/) - Comprehensive guide to jq filtering
- [JSON at Work](https://www.oreilly.com/library/view/json-at-work/9781491982389/) - O'Reilly book with extensive jq coverage

These resources range from beginner-friendly introductions to advanced
techniques, making it easier to find help regardless of your experience level
with jq.
