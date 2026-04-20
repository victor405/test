package main

import (
	"context"
	"database/sql"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"

	_ "github.com/go-sql-driver/mysql"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/rds"
	"github.com/aws/aws-sdk-go-v2/service/secretsmanager"
)

type Record struct {
	Prompt    string    `json:"prompt"`
	Answer    string    `json:"answer"`
	CreatedAt time.Time `json:"created_at"`
}

func getDB() (*sql.DB, error) {
	ctx := context.TODO()

	// AWS config
	cfg, err := config.LoadDefaultConfig(ctx)
	if err != nil {
		return nil, err
	}

	// Secrets Manager
	sm := secretsmanager.NewFromConfig(cfg)
	secretArn := os.Getenv("DB_SECRET_ARN")

	secretOut, err := sm.GetSecretValue(ctx, &secretsmanager.GetSecretValueInput{
		SecretId: &secretArn,
	})
	if err != nil {
		return nil, err
	}

	var secret map[string]string
	json.Unmarshal([]byte(*secretOut.SecretString), &secret)

	// RDS endpoint
	rdsClient := rds.NewFromConfig(cfg)
	dbs, err := rdsClient.DescribeDBInstances(ctx, &rds.DescribeDBInstancesInput{})
	if err != nil {
		return nil, err
	}

	host := *dbs.DBInstances[0].Endpoint.Address

	dsn := fmt.Sprintf("%s:%s@tcp(%s:3306)/demodb",
		secret["username"],
		secret["password"],
		host,
	)

	return sql.Open("mysql", dsn)
}

func historyHandler(w http.ResponseWriter, r *http.Request) {
	log.Println("Received /history request")

	db, err := getDB()
	if err != nil {
		log.Println("DB ERROR:", err)
		http.Error(w, err.Error(), 500)
		return
	}
	defer db.Close()

	rows, err := db.Query(`
		SELECT prompt, answer, created_at
		FROM prompt_history
		ORDER BY id DESC
		LIMIT 10
	`)
	if err != nil {
		log.Println("QUERY ERROR:", err)
		http.Error(w, err.Error(), 500)
		return
	}
	defer rows.Close()

	log.Println("Query successful")

	results := []Record{}

	for rows.Next() {
		var rec Record
		err := rows.Scan(&rec.Prompt, &rec.Answer, &rec.CreatedAt)
		if err != nil {
			log.Println("SCAN ERROR:", err)
			http.Error(w, err.Error(), 500)
			return
		}
		results = append(results, rec)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(results)
}

func main() {
	http.HandleFunc("/history", historyHandler)

	fmt.Println("Starting server on :80")
	log.Fatal(http.ListenAndServe(":80", nil))
}