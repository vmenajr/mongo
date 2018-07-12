package com.mongodb.app;

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

import com.beust.jcommander.Parameter;
import com.beust.jcommander.JCommander;

/**
 * Test Behavior when a new node is added to the replset
 * The new node will become primary and the app does not 
 * have it in the connection string
 */
public class App 
{
  @Parameter(names = { "-uri", }, description = "MongoDB URi")
  private String uri;
  
  public static void main( String[] args ) {
    App app = new App();
    JCommander.newBuilder()
      .addObject(app)
      .build()
      .parse(args);
    try {
      app.run();
    }
    catch (InterruptedException e) {
      System.out.println("App interrupted");
    }
    System.out.println("App exit");
  }

  public void run() throws InterruptedException {
    MongoClientURI connectionString = new MongoClientURI(uri);
    MongoClient mongoClient = new MongoClient(connectionString);
    MongoDatabase database = mongoClient.getDatabase("test");
    MongoCollection<Document> collection = database.getCollection("c");

    for (int i = 0; i < 30; i++) {
        Document document = new Document("ts", System.currentTimeMillis());
        try {
            collection.insertOne(document);
            Document myDoc = collection.find(document).first();
            System.out.println(myDoc.toJson());
            Thread.sleep(1000);
        }
        catch (com.mongodb.MongoException e) {
            System.out.println("MongoDB Exception, retrying in 5 seconds");
            Thread.sleep(5000);
        }
    }

    mongoClient.close();
  }
}
