package com.mongodb.app;

import com.mongodb.Block;
import com.mongodb.MongoClient;
import com.mongodb.MongoClientURI;
import com.mongodb.ServerAddress;
import com.mongodb.client.MongoCursor;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;
import com.mongodb.client.model.changestream.FullDocument;
import com.mongodb.client.model.changestream.ChangeStreamDocument;

import org.bson.Document;
import org.bson.BsonDocument;

import static com.mongodb.client.model.Filters.*;
import com.mongodb.client.result.DeleteResult;
import static com.mongodb.client.model.Updates.*;
import com.mongodb.client.result.UpdateResult;

import java.util.Arrays;
import java.util.ArrayList;
import java.util.List;
import java.util.Random;

import com.beust.jcommander.Parameter;
import com.beust.jcommander.JCommander;


import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.FileInputStream;
import java.io.FileOutputStream;
import java.io.IOException;
import java.io.ObjectInputStream;
import java.io.ObjectOutputStream;
 

/**
 * Test ChangeStream functionality
 */
public class App 
{
  @Parameter(names = { "-uri", }, description = "MongoDB URi")
  private String uri;
  @Parameter(names = { "-fromString", }, description = "Pass token on the command line")
  private String token;
  private MongoCollection<Document> coll;
  private Random rnd = new Random();
  
  public static void main( String[] args ) {
    App app = new App();
    JCommander.newBuilder()
      .addObject(app)
      .build()
      .parse(args);
    try {
		if (!app.token.isEmpty()) {
			app.runWithString();
		}
		else {
			app.run();
		}
    }
    catch (InterruptedException e) {
      System.out.println("App interrupted");
    }
    System.out.println("App exit");
  }

  public static void save(Object obj, String fileName) throws IOException {
          FileOutputStream fos = new FileOutputStream(fileName);
          BufferedOutputStream bos = new BufferedOutputStream(fos);
          ObjectOutputStream oos = new ObjectOutputStream(bos);
          oos.writeObject(obj);
          oos.close();
  }

  public static Object load(String fileName) throws IOException, ClassNotFoundException {
      FileInputStream fis = new FileInputStream(fileName);
      BufferedInputStream bis = new BufferedInputStream(fis);
      ObjectInputStream ois = new ObjectInputStream(bis);
      Object obj = ois.readObject();
      ois.close();
      return obj;
  }

  private void insertOne() {
      Document d = new Document("v", rnd.nextInt());
      coll.insertOne(d);
      System.out.println("Inserted: "+d);
      System.out.println();
  }

  public void run() throws InterruptedException {
    MongoClientURI connectionString = new MongoClientURI(uri);
    MongoClient mongoClient = new MongoClient(connectionString);
    MongoDatabase database = mongoClient.getDatabase("test");
    coll = database.getCollection("c");

    Block<ChangeStreamDocument<Document>> printBlock = new Block<>() {
        @Override
        public void apply(final ChangeStreamDocument<Document> changeStreamDocument) {
            System.out.println(changeStreamDocument);
            System.out.println();
        }
    };

    // Get token and save it to string variable
    String srt;
    {
        MongoCursor<ChangeStreamDocument<Document>> cursor = coll.watch().iterator();
        System.out.println();
        insertOne();
        ChangeStreamDocument<Document> next = cursor.next();
        printBlock.apply(next);

        srt = next.getResumeToken().toJson();
        System.out.println("ResumeToken1: "+srt);
        System.out.println();
    }

    insertOne();

    // Open new watch using string token and save new token to file
    {
        BsonDocument rt = BsonDocument.parse(srt);
        MongoCursor<ChangeStreamDocument<Document>> cursor = coll.watch().resumeAfter(rt).iterator();
        ChangeStreamDocument<Document> next = cursor.next();
        printBlock.apply(next);

        srt = next.getResumeToken().toJson();
        System.out.println("ResumeToken2: "+srt);
        System.out.println();

        try {
            save(srt, "test.json");
        }
        catch (IOException e) {
          System.out.println(e);
        }
    }

    insertOne();

    // Open new watch using token from filesystem
    {
        try {
            srt = (String)load("test.json");
            System.out.println("ResumeToken3: "+srt);
            System.out.println();
            BsonDocument rt = BsonDocument.parse(srt);
            MongoCursor<ChangeStreamDocument<Document>> cursor = coll.watch().resumeAfter(rt).iterator();
            ChangeStreamDocument<Document> next = cursor.next();
            printBlock.apply(next);
        }
        catch (IOException e) {
          System.out.println(e);
        }
        catch (ClassNotFoundException e) {
          System.out.println(e);
        }
    }

    System.out.println();
    mongoClient.close();
  }

  public void runWithString() throws InterruptedException {
    MongoClientURI connectionString = new MongoClientURI(uri);
    MongoClient mongoClient = new MongoClient(connectionString);
    MongoDatabase database = mongoClient.getDatabase("test");
    coll = database.getCollection("c");
    System.out.println();
    System.out.println("InputToken: "+token);

    Block<ChangeStreamDocument<Document>> printBlock = new Block<>() {
        @Override
        public void apply(final ChangeStreamDocument<Document> changeStreamDocument) {
            System.out.println(changeStreamDocument);
            System.out.println();
        }
    };

    // Get token and save it to string variable
	BsonDocument rt = BsonDocument.parse(token);
	MongoCursor<ChangeStreamDocument<Document>> cursor = coll.watch().resumeAfter(rt).iterator();
	ChangeStreamDocument<Document> next = cursor.next();
	printBlock.apply(next);
    System.out.println();
    mongoClient.close();
  }
}

