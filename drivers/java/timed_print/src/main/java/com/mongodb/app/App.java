package com.mongodb.app;

import com.mongodb.Block;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;

import org.bson.Document;
import org.bson.BsonDocument;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.JCommander;

import java.util.Date;
 
            

/**
 * Timed printing of documents
 */
public class App 
{
  @Parameter(names = { "-uri", }, description = "MongoDB URi")
  private String uri;
  @Parameter(names = { "-d", }, description = "Database name")
  private String dbName;
  @Parameter(names = { "-c", }, description = "Collection name")
  private String tblName;

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
    MongoDatabase database = mongoClient.getDatabase(dbName);
    MongoCollection<Document> coll = database.getCollection(tblName);

    Block<Document> printBlock = new Block<Document>() {
        @Override
        public void apply(final Document doc) {
            String id = doc.getString("_id");
            System.out.format("%s: Document id: %s", new Date().toInstant(), id);
            System.out.println();
        }
    };

    coll.find().forEach(printBlock);
    System.out.println();
    mongoClient.close();
  }
}

