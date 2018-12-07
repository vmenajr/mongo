package com.mongodb.app;

import com.mongodb.Block;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.WriteConcern;

import org.bson.Document;
import org.bson.BsonDocument;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.JCommander;

import java.util.Date;
 
            

/**
 * Use a write concern of n
 */
public class App 
{
  @Parameter(names = { "-uri", }, description = "MongoDB URi")
  private String uri;
  //@Parameter(names = { "-w", }, description = "Write Concern")
  //private String concern;

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
    MongoCollection<Document> collection = database.getCollection("c").withWriteConcern(WriteConcern.W3);

    Block<Document> printBlock = new Block<Document>() {
        @Override
        public void apply(final Document doc) {
            String id = doc.getObjectId("_id").toString();
            System.out.format("%s: Document id: %s", new Date().toInstant(), id);
            System.out.println();
        }
    };

    collection.insertOne(new Document("name", "Café Con Leche"));
    collection.find().forEach(printBlock);

    collection.deleteMany(new Document());
    collection.find().forEach(printBlock);
    
    System.out.println();
    mongoClient.close();
  }
}

