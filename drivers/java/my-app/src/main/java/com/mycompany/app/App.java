package com.mycompany.app;

import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.ServerAddress;

import com.mongodb.client.MongoDatabase;
import com.mongodb.client.MongoCollection;

import org.bson.Document;
import java.util.Arrays;
import com.mongodb.Block;

import com.mongodb.client.MongoCursor;
import static com.mongodb.client.model.Filters.*;
import com.mongodb.client.result.DeleteResult;
import static com.mongodb.client.model.Updates.*;
import com.mongodb.client.result.UpdateResult;
import java.util.ArrayList;
import java.util.List;


/**
 * Query test.c
 *
 */
public class App 
{
    public static void main( String[] args ) throws InterruptedException {
		//MongoClientURI connectionString = new MongoClientURI("mongodb://localhost:27018/test?readPreference=secondary");
		MongoClientURI connectionString = new MongoClientURI("mongodb://localhost:27017,localhost:27018,localhost:27019");
		MongoClient mongoClient = new MongoClient(connectionString);
		//MongoClient mongoClient = new MongoClient("localhost", 27018);
		MongoDatabase database = mongoClient.getDatabase("test");
		MongoCollection<Document> collection = database.getCollection("c");
		Document myDoc = collection.find().first();
		System.out.println(myDoc.toJson());
        Thread.sleep(30*1000);
    }
}
