# Hanzi2PinyinEngine
Hanzi to Pinyin engine in Swift

## Documentation

#### Alogrithm Overview

In general, our algorithm takes a Pinyin string as input and output a list of Chinese sentences where sentences are sorted in terms of their probability. The Pinyin string will first be transformed into a syllable graph. Then, a list of valid Pinyin sequences can be generated using the syllable graph. Using the Pinyin sequences, a lexicon graph can be generated and this is where we transform Pinyin into Chinese characters. After that, we will use our knowledge from the statistical language model to build a SLM Graph that joins lexicon together to form a sentence in Chinese.

![](https://github.com/Olament/Hanzi2PinyinEngine/blob/master/imgs/algorithm_overview.jpg)

To prevent confusion, I made a table to explain all the jargon above.

|                 |                          Definition                          |          Example          |
| :-------------: | :----------------------------------------------------------: | :-----------------------: |
|    Syllable     |                 the smallest unit of Pinyin                  | *ni*, *hao*, *pin*, *yin* |
| Pinyin Sequence |                    a sequence of syllable                    |    *ni'hao*, *pin'yin*    |
| Lexicon/Lattice | the smallest unit of meaningful Chinese (it could be both single or multiple Chinese characters) |        你好, 拼音         |
|    Sentence     |                    a sequence of lexicon                     |         你好拼音          |

### Syllable Graph

In this part, we will discuss how do we use the syllable graph to convert raw Pinyin string that from users into valid Pinyin sequences.

You may notice that for all Pinyin sequence above, I use ``'`` to separate each syllable from each other. However, when users input the Pinyin string, they are not kind enough to use ```'``` to separate them apart. Therefore, we need to build a syllable graph to generate valid syllable sequences from raw Pinyin input.

Let's start with an example, for raw Pinyin string *xian*, we can build a syllable graph where each vertex represent a character. Notice that we also add a dummy vertex at the end.

![](https://github.com/Olament/Hanzi2PinyinEngine/blob/master/imgs/syllable_graph_1.jpg)

Then, for a Pinyin raw string ```S``` , we add an edge incident to vertex ```i``` and vertex ```j``` if and only ```S[i:j-1]``` is a Pinyin syllable. For example, we will add an edge to connect *x* and *a* because *xi* is a valid Pinyin syllable. 

![](https://github.com/Olament/Hanzi2PinyinEngine/blob/master/imgs/syllable_graph_2.jpg)

After adding all the edge, you will realize that not all Pinyin syllable is part of a valid Pinyin sequence. For example, *xi'an* is a valid Pinyin sequence while *xia'n* is not because *n* is not a valid syllable. From the graph perspective, we observe that a Pinyin sequence is a valid Pinyin sequence if and only if there exists a path from the first (left-most) vertex to the last dummy vertex. Then, *xi'an* and *xian* are valid Pinyin sequence but *xia'n* and *xi'a'n* are not. 

For the sake of simplicity and to avoid unnecessary memory usage, we can "shrink" the graph by removing unused vertices and edges from the graph.

![](https://github.com/Olament/Hanzi2PinyinEngine/blob/master/imgs/syllable_graph_3.jpg)

In this example, we removed vertex *i* and vertex *n* since they never appear on any path from the first vertex to the last dummy vertex. And the two edges were for the same reason.

Now, we have our final syllable graph which will be passed to the next step to form a  lexicon graph. Also, we managed to obtain two valid Pinyin sequences *xi'an* and *xian* from the raw Pinyin input *xian*.

### Lexicon Graph

Based on the syllable graph, we can construct a lexicon graph that each edge represents a Chinese lexicon. We will need a procedure that translates Pinyin syllable to all possible Chinese lexicon. Such procedure can be implemented using an R-trie or even a database. However, we will skip the detail implementation here since this procedure is not the main focus of this post.

![](https://github.com/Olament/Hanzi2PinyinEngine/blob/master/imgs/lexicon_graph_1.jpg)

In the lexicon graph, we substitute edge from syllable graph to lexicon. For example, syllable *xi* can be translated into *系, 西, 洗, 喜* and many more Chinese lexicons. For each possible translation of syllable, we add an edge that incidents to the same vertices of the syllable edge and store this Chinese lexicon in the edge.

### SLM Graph

Having a lexicon graph that each edge represents a Chinese lexicon, we can form a Chinese sentence by joining a sequence of edges in a path from the first vertex to the last dummy node. By exhausting all possible paths from the first vertex to the last dummy vertex, we can generate all possible Chinese sentences from the raw Pinyin string given by the user. But we also want to get the probability of each sentence in the process so that we can present Chinese sentences to the user in the order of sentences' probability. 

To calculate the probability of each sentence, we first construct a line graph of lexicon graph. Recall that ```L(G)``` of a graph ```G``` is obtained by creating a vertex per edge in ```G``` and connect two vertex in ```L(G)``` if and only if such two edges is incident to the same vertex in ```G```. We also add a start vertex ```(S)``` and end vertex ```(T)``` to denote the start and the end of the SLM Graph.

![](https://github.com/Olament/Hanzi2PinyinEngine/blob/master/imgs/slm_graph_1.jpg)

After the transformation, we obtain a graph above, where each vertex in the graph is a lexicon. Then, we should add weight to each directed edge in our SLM graph such that a directed edge from vertex $i$ to vertex $j$ has a weight ```P(i|j)``` from our statistic learning model.

We can now calculate the probability of a sentence by finding its accumulated weight

## Acknowledge
Thanks to Mr. Guo Jiabao for open sourcing his [implementation](https://www.byvoid.com/zht/blog/slm_based_pinyin_ime) of SLM-based Pinyin inference algorithm. My algorithm would not be possible without this. We also thanks [岁寒](https://zhuanlan.zhihu.com/p/28332648) for sharing optimazation techniques on this topic.
