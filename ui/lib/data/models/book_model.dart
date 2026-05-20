class BookModel {
  final String id;
  final String title;
  final String author;
  final String? isbn;
  final String? publisher;
  final int? publishedYear;
  final String? category;
  final int totalCopies;
  final int availableCopies;
  final String? coverUrl;
  final DateTime? createdAt;

  BookModel({
    required this.id,
    required this.title,
    required this.author,
    this.isbn,
    this.publisher,
    this.publishedYear,
    this.category,
    required this.totalCopies,
    required this.availableCopies,
    this.coverUrl,
    this.createdAt,
  });

  factory BookModel.fromJson(Map<String, dynamic> json) {
    return BookModel(
      id: json['id'] ?? json['Id'] ?? '',
      title: json['name'] ?? json['Name'] ?? json['title'] ?? '',
      author: json['authorName'] ?? json['AuthorName'] ?? json['author'] ?? '',
      isbn: json['isbn'],
      publisher: json['publisher'],
      publishedYear: json['publishedYear'],
      category: json['genre'] ?? json['Genre'] ?? json['category'],
      totalCopies: json['totalCopies'] ?? json['TotalCopies'] ?? 1,
      availableCopies: json['availableCopies'] ?? json['AvailableCopies'] ?? 0,
      coverUrl: json['coverUrl'] ?? json['CoverUrl'],
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'Name': title,
        'AuthorName': author,
        if (isbn != null) 'isbn': isbn,
        if (publisher != null) 'publisher': publisher,
        if (publishedYear != null) 'publishedYear': publishedYear,
        if (category != null) 'Genre': category,
        'TotalCopies': totalCopies,
        'AvailableCopies': availableCopies,
      };

  bool get isAvailable => availableCopies > 0;

  String get availabilityLabel =>
      isAvailable ? '$availableCopies available' : 'Not available';
}
