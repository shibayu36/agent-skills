#!/usr/bin/env bash
# Fixture for scenario D: a Go 1.21 module that pages through users.

set -euo pipefail

TEST_DIR=$(mktemp -d "${TMPDIR:-/tmp}/research-before-design-test-D.XXXXXX")
cd "$TEST_DIR"

cat > go.mod <<'EOF'
module example.com/usersvc

go 1.21

require github.com/jackc/pgx/v5 v5.5.0
EOF

cat > main.go <<'EOF'
package main

import (
	"fmt"
	"log"
)

type User struct {
	ID   int64
	Name string
}

// ListUsersPage returns up to limit users whose ID is greater than afterID, ordered by ID.
func ListUsersPage(afterID int64, limit int) ([]User, error) {
	return nil, nil
}

func main() {
	users, err := ListUsersPage(0, 100)
	if err != nil {
		log.Fatal(err)
	}
	for _, u := range users {
		fmt.Println(u.ID, u.Name)
	}
}
EOF

echo "TEST_DIR=$TEST_DIR"
